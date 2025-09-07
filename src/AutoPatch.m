classdef AutoPatch < handle
    properties
        %% model
        bm              % benchmark
        bmType          % type of benchmark ('simulink' or 'nonSimulink')
        mdl             % the model with problematic NN controller
        mdl_m           % the copy of mdl before bug injection
        mdl_b           % the buggy model (with artificial bugs)
        cachedBr        % simulation acceleration
        D_run           % dataset for simulation, including ps_x and ps_y
        is_nor          % is normalized or not
        D               % the dataset from which to generate the test suite
        D_size          % the size of the dataset
        T               % simulation time
        Ts              % sampling interval
        mutInfo
        trajLen
        %% nn parameters
        net             % neural network controller
        nnType          % nn type, FFNN/LRNN/...
        nnStru          % nn structure (includes the output layer)
        hLNum           % the number of hidden layers (does not include output layer)
        weight          % weight of hidden layers and output layer stored as a cell array according to the layer index
        bias            % bias of hidden layers and output layer stored as a cell array according to the layer index
        weight_list
        minW            % Minimum weight value
        maxW            % Maximum weight value
        %% Settings for the model's input signal
        in_name         % input signal of the model
        in_range        % the range of the input signal
        in_span         % the time span of the input signal
        %% the input signal of the controller
        icc_name        % the input constant of the controller
        ics_name        % the input signal of the controller
        ic_const        % the input constant value of the controller
        %% config of output signal of controller
        oc_name         % output signal of controller
        oc_span         % the time span of output signal
        %% specification
        phiStr
        phi
        %% parameters of fault localization
        startL          % index of the starting layer
        endL            % index of the ending layer
        posNum4TS       % record the number of the weights with a non-zero FI of current mutant
        %% the parameters of differential evolution algorithm
        dim             % individual dimension
    end
    methods
        function this = AutoPatch(bm, bmType, mdl, mdl_m, D_run, is_nor, D, D_size, net, nnStru, T, Ts, mutInfo, in_name, in_range, in_span, icc_name, ic_const, ics_name, oc_name, oc_span, phiStr)
            this.bm = bm;
            this.bmType = bmType;
            this.mdl = mdl;
            this.mdl_m = mdl_m;
            this.D_run = D_run;
            this.is_nor = is_nor;
            this.D = D;
            this.D_size = D_size;

            this.T = T;
            this.Ts = Ts;
            this.mutInfo = mutInfo;

            this.net = net;
            [this.nnType, this.nnStru, this.hLNum, this.weight, this.bias, this.minW, this.maxW] = extractNNInfo(bm, net, nnStru);

            % Here, we only consider the weights between the hidden layers
            this.startL = 2;
            this.endL = this.hLNum;

            if this.nnStru ~= nnStru
                error('Layer structure mismatch between nnStru and the neural network!');
            end
            this.trajLen = T/Ts + 1;

            this.in_name = in_name;
            this.in_range = in_range;
            this.in_span = cell2mat(in_span);

            this.icc_name = icc_name;
            this.ic_const = ic_const;
            this.ics_name = ics_name;

            this.oc_name = oc_name;
            this.oc_span = cell2mat(oc_span);

            this.phiStr = phiStr;
            this.phi = STL_Formula('phi', this.phiStr);
        end
        %% functions
        function [rob, Br, taus, nnInputs, nnOutputs] = signalDiagnosis(this, mdl, Br, sysInputs)
            % signalDiagnosis function returns the robustness, Br, tau_s, controller's input signal and controller's output signal of a system execution
            %
            % Inputs:
            %   mdl: simulink model
            %   Br: BreachSimulinkSystem of the Simulink model
            %   sysInputs: the input signals of the simulink model
            % Outputs:
            %   rob: robustness
            %   Br: BreachSimulinkSystem of the Simulink model
            %   taus: the first timestamp at which the robustness value turns negative
            %   nnInputs: input signal of controller
            %   nnOutputs: output signal of controller

            [rob, Br] = calRob(mdl, Br, this.T, this.Ts, this.in_name, this.in_span, this.phi, sysInputs);

            % extract ic signal and oc signal for forward impact analysis
            % (analysis the impact of a weight to the final result)
            nnInputs = sigMatch(Br, this.ics_name);
            nnOutputs = sigMatch(Br, this.oc_name);

            if this.is_nor == 1
                x_gain = this.D_run.ps_x.gain;
                x_gain = diag(x_gain);
                x_offset = this.D_run.ps_x.xoffset;
                nnInputs = nnInputs - x_offset;
                nnInputs = x_gain * nnInputs;

                y_gain = this.D_run.ps_y.gain;
                y_offset = this.D_run.ps_y.xoffset;
                nnOutputs = nnOutputs/y_gain;
                nnOutputs = nnOutputs + y_offset;
            end

            % calculate the tau_s according to the given specification
            if rob > 0
                taus = this.T;
                return;
            end
            
            [taus, validVioIdx] = extractTaus(this.bm, mdl, this.T, this.Ts, Br, sysInputs, this.phiStr);

           
            % extract the input and output signals of nn controller in the interval [0, tau_s]
            nnInputs = nnInputs(:,1:validVioIdx(1,1));
            nnOutputs = nnOutputs(:,1:validVioIdx(1,1));

            % the following codes have bugs on ACC2_spec2_dataset1_index_8, WT
            % % localize tau_s using online monitoring. Thank you, Zhenya
            % tau = 0;
            % time_ = Br.P.traj{1}.time;
            % time = round(time_, 2);
            % sig_list = cellstr(split(this.sig_str, ","));
            % X = sigMatch(Br, sig_list);
            % trace = [time; X];
            % [rob_up, rob_low] = stl_eval_mex_pw(this.sig_str, this.phiStr, trace, tau);
            % rob_neg = find(rob_up < 0);
            % tau_s = (rob_neg(1, 1) - 1) * this.Ts;
        end

        function [weight2Neuron, neuronOut] = weightToNeuron(this, input)
            % weightToNeuron function calculates the first  of the feed forward impact.
            % (a weight of a neuron to the output of this neuron)
            %
            % Inputs:
            %   input: input signal of nn at a timestamp (at a certain frame)
            % Outputs:
            %   weight2Neuron: the impact of a weight of a neuron to the output of this neuron during a system execution
            %   neuronOut: the output of each neuron during a system execution

            % calculate the frame number in a system execution (tau_s/Ts)
            [row, column] = size(input);
            % initialize the neuronOut to store neuronOutSnapShot
            neuronOut = {};
            % initialize the weight2Neuron to store weight2NeuronSnapShot
            weight2Neuron = {};

            for j = 1: column
                % record the output of each neuron at a certain frame
                neuronOutSnapShot = initVar(this.net, this.nnStru, 'neuronOutSnapShot');
                % record the impact of a weight of a neuron to the output of this neuron at a certain frame
                weight2NeuronSnapShot = initVar(this.net, this.nnStru, 'weight2NeuronSnapShot');
                for i = 1: this.net.numLayers
                    if i == 1
                        transFcn = this.net.layers{i}.transferFcn();
                        transFcn = str2func(transFcn);
                        neuronOutSnapShot{1,1} = transFcn(this.weight{1,1} * input(:,j) + this.bias{1, i});
                        % calculate the impact of an input weight of a neuron to the output of this neuron
                        for ni = 1: this.nnStru(1,i)
                            % the absolute sum of current neuron
                            weightoutSum = abs(this.weight{1,1}(ni,:)) * abs(input(:,j));
                            % calculate weight2NeuronSnapShot one by one
                            for wi = 1:row
                                weight2NeuronSnapShot{1,1}(ni,wi) = abs(this.weight{1,1}(ni,wi)) * abs(input(wi,j))/weightoutSum;
                            end
                        end
                    else
                        transFcn = this.net.layers{i}.transferFcn();
                        transFcn = str2func(transFcn);
                        neuronOutSnapShot{1,i} = transFcn(this.weight{1,i} * neuronOutSnapShot{1,i-1} + this.bias{1, i});
                        % calculate the impact of a layer weight of a neuron to the output of this neuron.
                        for ni = 1: this.nnStru(1,i)
                            % the absolute sum of current neuron
                            weightoutSum = abs(this.weight{1,i}(ni,:)) * abs(neuronOutSnapShot{1,i-1});
                            % calculate weight2NeuronSnapShot one by one
                            for wi = 1:this.nnStru(1,i-1)
                                weight2NeuronSnapShot{1,i}(ni,wi) = abs(this.weight{1,i}(ni,wi)) * abs(neuronOutSnapShot{1,i-1}(wi,1))/weightoutSum;
                            end
                        end
                    end
                end
                neuronOut{end+1} = neuronOutSnapShot;
                weight2Neuron{end+1} = weight2NeuronSnapShot;
            end
        end

        function [output, doutdneout] = neuronToOutputGradient(this, layerOut, layer_idx)
            % neuronToOutputGradient function calculates the gradient of
            % the final output to the output of a neuron at a certain layer.
            %
            % Inputs:
            %   layerOut: the output of the neurons at a certain layer
            %   layer_idx: range: [1, this.hLNum]
            % Outputs:
            %   output: final output in the form of dlarray
            %   doutdneout: the derivative of the final output to the
            %   output of an neuron at a certain layer.

            % assign neuronOut to a temp variable a_prev
            a_prev = layerOut;
            % perform inference to show how neuronOut turn into output
            for li = layer_idx: this.hLNum
                transFcn = this.net.layers{li+1}.transferFcn();
                transFcn = str2func(transFcn);
                a_prev = transFcn(this.weight{1, li+1} * a_prev + this.bias{1, li+1});
            end

            % assign the final temp variable a_prev to output
            output = a_prev;
            % calculate the gradient of the final output to the output of
            % the neurons at a certain layer
            doutdneout = dlgradient(output, layerOut);
        end

        function [neuron2Out] = neuronToOutput(this, input, neuronOut)
            % neuronToOutput function calculates the second part of the feed forward impact.
            % (the impact of a neuron's output at a certain layer to the final output)
            %
            % Inputs:
            %   input: input signal of nn at a timestamp (at a certain frame)
            %   neuronOut: the output of each neuron during a system execution
            % Outputs:
            %   neuron2Out: the gradient of the final output to the output of a neuron at a certain layer, i.e.,
            %   the impact of the output of a neuron to the final output during a system execution

            % calculate the frame number in a system execution (tau_s/Ts)
            [~, column] = size(input);
            % initialize the neuron2Out to store neuron2OutSnapShot
            neuron2Out = {};

            for j = 1:column
                % record the impact of the output of a neuron to the final output at a certain frame
                neuron2OutSnapShot = initVar(this.net, this.nnStru, 'neuron2OutSnapShot');
                for li = 1:this.hLNum
                    layerOut = dlarray(neuronOut{1,j}{1,li});
                    [fval, gradval] = dlfeval(@this.neuronToOutputGradient, layerOut, li);
                    % dlarray to mat
                    neuron2OutSnapShot{1,li} = extractdata(gradval);
                end
                neuron2Out{end+1} = neuron2OutSnapShot;
            end
        end

        function diagInfo = forwardImpactAnalysis(this, mdl, sysInputs, tci)
            % Given an external input signal of the system, forwardImpactAnalysis function returns the diagnostic information
            % of current system execution.
            % Inputs:
            %   mdl: simulink modelthe diagnostic information of the forward  impactof current system execution.
            %   sysInputs: the input signals of the simulink model
            % Outputs:
            %   diagInfo: a struct store the diagnostic information of the forward impact of current system execution.
            %   diagInfo.Br: BreachSimulinkSystem of the Simulink model
            %   diagInfo.rob: robustness value
            %   diagInfo.state: the state of current system execution, passed or failed
            %   diagInfo.tau_s: the first timestamp at which the robustness value turns negative
            %   diagInfo.nnInputs: input signal of controller during [0, tau_s]
            %   diagInfo.nnOutputs: output signal of controller during [0, tau_s]
            %   diagInfo.weight2Neuron: the impact of a weight of a neuron to the output of this neuron during a system execution
            %   diagInfo.neuronOut: the output of each neuron during a system execution
            %   diagInfo.neuron2Out: the gradient of the final output to the output of a neuron at a certain layer, i.e., the impact of the output of a neuron to the final output during a system execution
            %   diagInfo.weight2Out: the forward impact of each weight to the final output during a system execution
            
            
            % perform signal diagnosis
            if strcmp(this.bm, 'UUV') || strcmp(this.bm, 'MC')
                Br = [];
                rob = this.D.testCases(tci).rob;
                taus = this.D.testCases(tci).taus;
                nnInputs = this.D.testCases(tci).nnInputs;
                nnOutputs = this.D.testCases(tci).nnOutputs;
            else
                % we can reuse Br to accelerate simulation
                if tci == 1
                    Br = BreachSimulinkSystem(mdl);
                    Br.Sys.tspan = 0:this.Ts:this.T;
                    this.cachedBr = Br;
                end
                [rob, Br, taus, nnInputs, nnOutputs] = this.signalDiagnosis(mdl, this.cachedBr, sysInputs);
                this.cachedBr = Br;
            end
            

            % calculate the frame number in a system execution (taus/Ts)
            [~, frameNum] = size(nnInputs);

            % initialize weight2Out
            weight2Out = cell(1, frameNum);

            % obtain the state of the system execution
            if rob >= 0
                state = 1;
            else
                state = 0;
            end

            % calculate the first part
            [weight2Neuron, neuronOut] = this.weightToNeuron(nnInputs);
            % calculate the second part
            [neuron2Out] = this.neuronToOutput(nnInputs, neuronOut);
            % calculate weight2Out by first part * second part
            for fi = 1:frameNum
                % record the impact of a weight of a neuron to the final output at a certain frame
                weight2OutSnapShot = initVar(this.net, this.nnStru, 'weight2OutSnapShot');
                for li = 1:this.hLNum + 1
                    if li < this.hLNum + 1
                        [~,col] = size(weight2Neuron{1,fi}{1,li});
                        % expand
                        expandedNeuron2Out = repmat(neuron2Out{1,fi}{1,li}, 1, col);
                        % multiply the corresponding positions of the
                        % weight2Neuron matrix and the expanded neuron2Out vector
                        weight2OutSnapShot{1,li} = weight2Neuron{1,fi}{1,li} .* expandedNeuron2Out;
                    else
                        weight2OutSnapShot{1,li} = weight2Neuron{1,fi}{1,li};
                    end
                end
                weight2Out{1, fi} = weight2OutSnapShot;
            end

            diagInfo.Br = Br;
            diagInfo.rob = rob;
            diagInfo.state = state;
            diagInfo.taus = taus;
            diagInfo.nnInputs = nnInputs;
            diagInfo.nnOutputs = nnOutputs;
            diagInfo.weight2Neuron = weight2Neuron;
            diagInfo.neuronOut = neuronOut;
            diagInfo.neuron2Out = neuron2Out;
            diagInfo.weight2Out = weight2Out;
        end

        function [act_weight_info, weight2OutSnapShotBinary] = selectActWeight(this, weight2OutSnapShot)
            %  selectActWeight function returns the activated weights.
            %
            % Inputs:
            %   weight2OutSnapShot: execution spectrum at a certain frame
            % Outputs:
            %   act_weight_info: includes current weight's weight2OutSnapShot, layer_idx, right_endpoint_idx, left_endpoint_idx
            %   weight2OutSnapShotBinary: if a weight's forward impact is greater than 0, its weight2OutSnapShotBinary is 1; otherwise, 0.

            % initialize act_weight_info
            act_weight_info = {};
            for li = 1:this.hLNum + 1
                act_weight_info{end+1} = [];
            end

            % record the binary impact of a weight to the final output at a certain frame
            weight2OutSnapShotBinary = weight2OutSnapShot;

            % record the activated weights
            for li = this.startL:this.endL
                [row, column] = size(weight2OutSnapShot{1,li});
                for i = 1:row
                    for j = 1:column
                        if weight2OutSnapShot{1,li}(i,j) ~= 0
                            act_weight_info{1, li}(end+1, :) = [abs(weight2OutSnapShot{1,li}(i,j)), li, i, j];
                            weight2OutSnapShotBinary{1, li}(i, j) = 1;
                        end
                    end
                end
            end
        end

        function [topk_weight_info, weight2OutSnapShotBinary] = selectDescTopkWeight(this, weight2OutSnapShot, hc, in_i)
            % selectDescTopkWeight function returns topk weights from the weights with a positive forward impact. (ef)
            %
            % Inputs:
            %   weight2OutSnapShot: execution spectrum at a certain frame
            %   topk: the number of weights ranked in the topk at each hidden layer
            % Outputs:
            %   topk_weight_info: includes singleWeight2OutSnapShot, layer_idx, right_endpoint_idx, left_endpoint_idx
            %   weight2OutSnapShotBinary: if a weight at a certain frame belongs topk_weight, 1; else, 0.

            % initialize topk_weight_info
            topk_weight_info = cell(1, this.hLNum + 1);
            % record the binary impact of a weight to the final output at a certain frame
            weight2OutSnapShotBinary = initVar(this.net, this.nnStru, 'weight2OutSnapShotBinary');

            % select and record the topk weights
            for li = this.startL:this.endL
                [row, column] = size(weight2OutSnapShot{1,li});
                % obtain the number of weights with a positive forward impact at current frame
                if strcmp(hc.topkMode, 'fixedRatio4TS')
                    posNum = this.posNum4TS(1,li);
                else
                    error('Check current topk_mode!');
                end
                li_topk_weight_info = zeros(ceil(posNum * hc.topk), 4);
                topk_weight_info{1,li} = li_topk_weight_info;
                if posNum == 0
                    % this situation is potentially plausible
                    continue;
                end

                for i = 1:row
                    for j = 1:column
                        if abs(weight2OutSnapShot{1,li}(i,j)) > topk_weight_info{1,li}(end,1)
                            topk_weight_info{1,li}(end,:) = [abs(weight2OutSnapShot{1,li}(i,j)), li, i, j];
                            topk_weight_info{1,li} = sortrows(topk_weight_info{1,li},-1);
                        end
                    end
                end
            end

            for li = this.startL:this.endL
                for i = 1:size(topk_weight_info{1,li},1)
                    % % in case topk is set too large or the case that
                    % % the number of positive values in weight2OutSnapShot is less than topk
                    if topk_weight_info{1,li}(i,1) > 0
                        weight2OutSnapShotBinary{1, topk_weight_info{1,li}(i,2)}(topk_weight_info{1,li}(i,3),topk_weight_info{1,li}(i,4)) = 1;
                    end
                end
            end
        end

        function hyCon = constructSpectrum(this, hyCon, diagInfoSuite)
            % accordinglyAssign function merges the execution spectrum of current system execution with
            % the execution spectrum of the system executions before.
            %
            % Inputs:
            %   hyCon:
            %   diagInfoSuite:
            % Outputs:
            %   hyCon:

            tsSize = numel(diagInfoSuite);
            hcNum = numel(hyCon);

            for tsi = 1:tsSize
                state = diagInfoSuite{tsi}.state;
                weight2Out = diagInfoSuite{tsi}.weight2Out;

                % frame number
                frameNum = numel(weight2Out);

                for hci = 1:hcNum
                    conf = hyCon(1,hci);

                    w = selectScalingFactor(this.trajLen, frameNum, this.Ts, state, conf);
                    % initialize weight2OutBinary by converting weight2Out in a binary form. if topk, 1; else, 0.
                    weight2OutBinary = cell(1,frameNum);

                    for fri = 1:frameNum
                        if strcmp(conf.esMode, 'topk')
                            % select topk weights according to hc, for ef. In this work, we only consider ef.
                            [~, weight2OutSnapShotBinary] = this.selectDescTopkWeight(weight2Out{1, fri}, conf, tsi);
                        elseif strcmp(conf.esMode, 'activated')
                            % select activated weights for each frame according to hc
                            [~, weight2OutSnapShotBinary] = this.selectActWeight(weight2Out{1, fri});
                        end
                        weight2OutBinary{1, fri} = weight2OutSnapShotBinary;
                    end

                    % 二值化之后，开始赋值
                    for fri = 1:frameNum
                        weight2OutSnapShotBinary = weight2OutBinary{1,fri};
                        for li = this.startL:this.endL
                            [row, column] = size(weight2OutSnapShotBinary{1,li});
                            for i = 1:row
                                for j = 1:column
                                    if state == 1 && weight2OutSnapShotBinary{1,li}(i,j) == 1
                                        exeSpectrumSnapShot = w(fri, 1) * [1,0,0,0];
                                    elseif state == 1 && weight2OutSnapShotBinary{1,li}(i,j) == 0
                                        exeSpectrumSnapShot = w(fri, 1) * [0,1,0,0];
                                    elseif state == 0 && weight2OutSnapShotBinary{1,li}(i,j) == 1
                                        exeSpectrumSnapShot = w(fri, 1) * [0,0,1,0];
                                    elseif state == 0 && weight2OutSnapShotBinary{1,li}(i,j) == 0
                                        exeSpectrumSnapShot = w(fri, 1) * [0,0,0,1];
                                    else
                                        error('check your state or weight2OutSnapShotBinary!');
                                    end
                                    hyCon(1,hci).exeSpectrum{1,li}{i,j} = hyCon(1,hci).exeSpectrum{1,li}{i,j} + exeSpectrumSnapShot;
                                end
                            end
                        end
                    end
                end
            end
        end

        function [hyMCon] = SBFL(this, hyMCon, sortMode)
            % SBFL function performs a spectrum-based fault localization.
            %
            % Inputs:
            %   hyMCon:
            % Outputs:
            %   hyMCon:

            [metNum, hcNum] = size(hyMCon);

            for mi = 1:metNum
                for hci = 1:hcNum
                    for li = this.startL:this.endL
                        [row,column] = size(hyMCon(mi,hci).exeSpectrum{1,li});
                        for i = 1:row
                            for j = 1:column
                                cs = hyMCon(mi,hci).exeSpectrum{li}{i,j};
                                score = spsCalculator(cs(1,1), cs(1,2), cs(1,3), cs(1,4), hyMCon(mi,hci).spsMetric);
                                % 在spsWeightList中找到对应的权重所在的行的索引
                                idx = ismember(hyMCon(mi,hci).spsWeightList(:,1:3), [li,i,j], 'rows');
                                % 给这个行的第四个值，也就是分数赋值
                                hyMCon(mi,hci).spsWeightList(idx,5) = score;
                            end
                        end
                    end
                    sortedSpsWeightList = sortSpsWeightList(hyMCon(mi,hci).spsWeightList, sortMode);
                    hyMCon(mi,hci).spsWeightList = sortedSpsWeightList;
                    % artificial fault
                    if ~isempty(this.mutInfo)
                        hyMCon(mi,hci).recallList = genRecallList(sortedSpsWeightList(:,1:3), this.mutInfo.mut_op(:,1:3));
                    end
                end
            end
        end

        function [candidate] = selectCandidate(this, TS, cand_mode)
            % selectCandidate function selects the candidates for mutation based on mut_mode.
            %
            % Inputs:
            %   mut_mode: the mode to select the weight candidates to be mutated
            % Outputs:
            %   candidate: the selected weight candidates

            candidate = [];
            if strcmp(cand_mode, 'rand')
                % obtain the idx of all weights
                for li = this.roil_l:this.roil_r
                    [rows, cols] = size(this.weight{1, li});
                    for i = 1:rows
                        for j = 1:cols
                            candidate = [candidate; li, i, j];
                        end
                    end
                end
            elseif strcmp(cand_mode, 'average')
                % obtain the idx of the weights with forward impact higher than the average
                for in_i = 1: numel(TS.tr_in_cell)
                    in_sig = TS.tr_in_cell{1, in_i};
                    diagInfo = this.forwardImpactAnalysis(this.mdl, in_sig);
                    % obtain top50_weight of current system execution
                    top50_weight = selectTop50Weight(diagInfo.weight2Out, this.roil_l, this.roil_r, cand_mode);
                    candidate = [candidate; top50_weight];
                end
                % remove duplicated rows
                candidate = unique(candidate(:,1:3), 'rows');
            end
        end

        function [mutant] = bugInjection(this, TS, candidate, mut_conf, mi)
            % bugInjection function returns a buggy model (aka a mutant) with K mutated weights.
            %
            % Inputs:
            %   TS: the test suite to assess the mutant. We need to make sure that
            %   the model before mutation (bug injection) can handle all the test cases correctly
            %   candidate: the weight candidates for mutation
            %   mut_conf: mutation config
            %   mi: the index of current mutant
            % Outputs:
            %   mutant

            if strcmp(mut_conf.bound_mode, 'natural')
                mut_conf.bug_lb = this.min_weight;
                mut_conf.bug_ub = this.max_weight;
            end

            mut_TS = TS;
            cand_num = size(candidate, 1);
            flag = 1;
            % mutate the model until the behavior changes
            while flag
                % randomly select K weights to perform mutation (insert an artificial bug to each of them)
                weight_idx = randperm(cand_num, mut_conf.K);
                rand_weight = candidate(weight_idx, :);
                bug_list = bugGenerator(mut_conf.bug_lb, mut_conf.bug_ub, mut_conf.dist_mode, mut_conf.K, this.weight_list);
                % generate the mutation operator
                mut_op = [rand_weight, bug_list];
                % the name of the faulty model
                bug_mdl = [this.mdl_m, '_bug_', num2str(mi), '_', mut_conf.date];
                % apply the above mutation operator to the simulink model
                mutateWeight(this.mdl_m, bug_mdl, mut_conf.mut_mode, mut_op);
                % obtain the weight mutated by the mutation operator (the weight of bug_mdl)
                [this.weight, ori_weight, spsWeights] = weightSync(this.net, mut_conf.mut_mode, mut_op);
                % update the robustness values of mut_TS
                for i = 1:mut_TS.size
                    in_sig = mut_TS.tr_in_cell{1, i};
                    [rob, ~] = calRob(bug_mdl, this.T, this.Ts, this.in_name, this.in_span, this.phi, in_sig);
                    mut_TS.tr_rob_set(i,1) = rob;
                    disp(rob);
                end

                % obtain the number of the test cases that current mutant can not handle
                delta_state = sum(mut_TS.tr_rob_set < 0);
                % satisfy the mutation requirement
                if delta_state >= mut_conf.bcr * mut_TS.size && delta_state <= (1 - mut_conf.bcr) * mut_TS.size
                    flag = 0;
                    % update this.mdl_b
                    this.mdl_b = bug_mdl;
                    % update this.dim
                    this.dim = mut_conf.K;
                    mut_TS.sn = sum(mut_TS.tr_rob_set > 0);
                end
            end

            mutant = struct();
            mutant.TS = TS;
            mutant.mut_TS = mut_TS;
            mutant.phi = this.phi;
            mutant.mut_mode = mut_conf.mut_mode;
            mutant.bound_mode = mut_conf.bound_mode;
            mutant.bug_lb = mut_conf.bug_lb;
            mutant.bug_ub = mut_conf.bug_ub;
            mutant.dist_mode = mut_conf.dist_mode;
            mutant.K = mut_conf.K;
            mutant.bcr = mut_conf.bcr;
            mutant.cand_mode = mut_conf.cand_mode;
            mutant.date = mut_conf.date;
            mutant.mi = mi;
            mutant.bug_mdl = bug_mdl;
            mutant.ori_weight = ori_weight;
            mutant.mut_op = mut_op;
            mutant.spsWeights = spsWeights;
            mutant.mut_op_prop_list = mut_conf.mut_op_prop_list;
            mutant.noise_rep_num = mut_conf.noise_rep_num;

            % store the mutated suspicious weights
            mutated_sps_weight_list = cell(mut_conf.noise_rep_num, numel(mut_conf.mut_op_prop_list));

            for i= 1:mut_conf.noise_rep_num
                for j = 1:numel(mut_conf.mut_op_prop_list)
                    cur_mut_op_mode = mutant.mut_op_prop_list{1,j}.mode;
                    cur_mut_op_noise = mutant.mut_op_prop_list{1,j}.noise;
                    if strcmp(cur_mut_op_mode, 'precise') && cur_mut_op_noise == 0
                        mutated_sps_weight_list{i,j} = mutant.spsWeights;
                    else
                        mutated_sps_weight_list{i, j} = this.mutateMutOp(mutant, cur_mut_op_mode, cur_mut_op_noise);
                    end
                end
            end
            mutant.mutated_sps_weight_list = mutated_sps_weight_list;
        end

        function [mutated_sps_weight] = mutateMutOp(this, mutant, mut_op_mode, mut_op_noise)
            % mutateMutOp function adds noise to spsWeights by mutation.
            %
            % Inputs:
            %   mutant:
            %   mut_op_mode: the mode to mutate the spsWeights, 'opacity' (replace part of spsWeights with noise) and
            %   'noise'(just add noise to spsWeights)
            %   mut_op_noise: the ratio of replaced or added weights to the original spsWeights
            % Outputs:
            %   mutated_sps_weight: mutated suspicious weights

            spsWeights = mutant.spsWeights;
            this.dim = mutant.K;

            % obtain the idx of all weights
            all_weight = [];
            for li = this.roil_l:this.roil_r
                [rows, cols] = size(this.weight{1, li});
                for i = 1:rows
                    for j = 1:cols
                        all_weight = [all_weight; li, i, j, this.weight{1,li}(i,j)];
                    end
                end
            end
            res_weight = setdiff(all_weight, spsWeights, 'rows');

            if strcmp(mut_op_mode, 'opacity')
                % the number of the weights to be discarded
                disc_num = round(this.dim * mut_op_noise);
                % randomly select the weight need to be discarded
                disc_idx = randperm(this.dim, disc_num);
                % remove the selected weight
                spsWeights(disc_idx,:) = [];
                % randomly select opacity_num weights to replace disc_weight
                noise_idx = randperm(size(res_weight,1), disc_num);
                noise_weight = res_weight(noise_idx, :);
                mutated_sps_weight = [spsWeights; noise_weight];
            elseif strcmp(mut_op_mode, 'noise')
                noise_num = round(this.dim * mut_op_noise);
                noise_idx = randperm(size(res_weight,1), noise_num);
                noise_weight = res_weight(noise_idx, :);
                mutated_sps_weight = [spsWeights; noise_weight];
            else
                error('Check the mutation mode!');
            end
        end

        function [bestIndLog, fullPopLog] = altWeightSearch(this, faultType, mutant, mutOpMode, mutOpNoise, flMode, spsWeights, fitnessMode, deParams, repLog_ID, coreNum, exConstParams, exNormParams)
            % altWeightSearch function performs a differential evolution algorithm to search for a set of alternative weights.
            %
            % Inputs:
            %   mutant:
            %   flMode:
            %   spsWeights: [li, i, j, oriVal, spsScore]
            %   fitnessMode: repair mode, i.e., the type of fitness function

            %   deParams: the parameters of differential evoluation
            %   algorithm, including popSize, maxGen, F, CR, mutSgy,
            %   crSgy, perturbation facto
            %   coreNum: core number
            % Outputs:


            % there is a bug! if the safety rate of two individuals are the same, we need to select the one with a greater robustness value sum

            % set a timer
            tic;

            if strcmp(deParams.initMode, 'internal')
                this.dim = size(spsWeights, 1);
                this.mdl_b = mutant.bug_mdl;
                % sort TS according to the robustness value of each test case
                sortedTS = sortTestSuite(mutant.mut_TS);

                if strcmp(faultType, 'artificial')
                    % reset this.weight (has been corrected in mutation phase)
                    [this.weight, ~, ~] = weightSync(this.net, mutant.mut_mode, mutant.mut_op);
                end

                % obtain the lb and ub of the suspicious weights
                [lb, ub] = obtainBound(spsWeights);
                oriPop = initPop(this.weight, spsWeights, deParams, lb, ub, true);

            elseif strcmp(deParams.initMode, 'external')
                % start repair from the break-point
                repLogDir = dir(fullfile(deParams.initFolder,'*.mat'));
                repLogNames = {repLogDir.name};

                str1 = ['_K_', num2str(repLog_ID.K), '_'];
                str2 = ['_', repLog_ID.mut_op_mode, '_', num2str(repLog_ID.mut_op_noise), '_'];
                str3 = ['_repmode_', fitnessMode, '_'];
                str4 = ['_mutant_', num2str(repLog_ID.mut_i), '_'];
                str5 = ['_budget_', num2str(repLog_ID.bi)];
                target_str = repLogNames(contains(repLogNames, str1) & contains(repLogNames, str2) & contains(repLogNames, str3) & contains(repLogNames, str4) & contains(repLogNames, str5));
                if numel(target_str) > 1 || numel(target_str) == 0
                    error('Check the deParams.initMode and deParams.initFolder!');
                end

                rep_log = load(target_str{1,1});
                this.dim = size(spsWeights, 1);
                this.mdl_b = mutant.bug_mdl;
                % sort TS according to the robustness value of each test case
                sortedTS = sortTestSuite(mutant.mut_TS);
                % reset this.weight (has been corrected in mutation phase)
                [this.weight, ~, ~] = weightSync(this.net, mutant.mut_mode, mutant.mut_op);

                % obtain the lb and ub of the suspicious weights
                [lb, ub] = obtainBound(spsWeights);
                nonempty_idx = find(~cellfun('isempty', rep_log.X_log));
                if ~isempty(nonempty_idx)
                    oriPop = rep_log.X_log{1, nonempty_idx(end)};
                else
                    error('Check the rep_log!');
                end
            else
                error('Check the deParams.initMode!');
            end

            [bestIndLog, fullPopLog, indFitRobMap, oriPopFitness, oriPopRobList, crPopFitness, crPopRobList] = initDELogs(sortedTS.size, deParams.popSize, deParams.maxGen);

            if contains(fitnessMode, 'cheapincr')
                calibPopFitness = oriPopFitness;
                calibPopRobList = oriPopRobList;
            end
            %% lookup table
            % start parallel computation
            initParpool(coreNum);
            % s = packVarsToStruct('bmType', this.bmType, 'mdl_b', this.mdl_b, 'T', this.T, 'Ts', this.Ts, ...
            %     'in_name', this.in_name, 'in_span', this.in_span, 'phi', this.phi, ...
            %     'weight', this.weight);

            modelInfo = struct();
            modelInfo.bm = this.bm;
            modelInfo.bmType = this.bmType;
            bmType_ = modelInfo.bmType;
            modelInfo.faultyMdl = this.mdl_b;
            modelInfo.oriWeights = this.weight;
            modelInfo.spsWeights = spsWeights;

            simConf = struct();
            simConf.T = this.T;
            simConf.Ts = this.Ts;
            simConf.in_name = this.in_name;
            simConf.in_span = this.in_span;
            simConf.phi = this.phi;

            % obtain the fitness value of the initial population
            geni = 1;
            parfor popi = 1:deParams.popSize
                deFlag = 'or';
                altWeights = oriPop(popi, :);
                if strcmp(bmType_, 'simulink')
                    assignStructToBase(exConstParams);
                    assignStructToBase(exNormParams);
                end

                searchConf = initSearchConf(geni, popi, fitnessMode, deFlag, altWeights, false);
                [oriPopFitness(1, popi), oriPopRobList(:, popi)] = fitness(modelInfo, simConf, searchConf, sortedTS);
            end

            % update map
            indFitRobMap = updateIndFitRobMap(indFitRobMap, oriPop, oriPopFitness, oriPopRobList);

            % iterate
            for geni = 1:deParams.maxGen

                % find best individual in each generation
                [bestInd, bestFitness, bestRobList]  = findBestIndividual(oriPop, oriPopFitness, oriPopRobList);

                % mutation
                V = mutation(oriPop, bestInd, deParams.F, deParams.mutSgy);
                % crossover
                crPop = crossover(oriPop, V, lb, ub, deParams.CR, deParams.crSgy);

                parfor popi = 1:deParams.popSize
                    try
                        deFlag = 'cr';
                        altWeights = crPop(popi, :);

                        [queriedFitness, queriedRobList, isFound] = queryIndFitRobMap(indFitRobMap, altWeights);

                        if isFound
                            disp('Match successful!');
                            crPopFitness(1, popi) = queriedFitness;
                            crPopRobList(:, popi) = queriedRobList;
                        else
                            % for parallel
                            if strcmp(bmType_, 'simulink')
                                assignStructToBase(exConstParams);
                                assignStructToBase(exNormParams);
                            end

                            searchConf = initSearchConf(geni, popi, fitnessMode, deFlag, altWeights, true, [], oriPopFitness);
                            [crPopFitness(1, popi), crPopRobList(:, popi)] = fitness(modelInfo, simConf, searchConf, sortedTS);
                        end

                    catch e
                        % 打印详细错误信息
                        fprintf('\n[Error] Generation %d - Individual %d failed:\n', geni, popi);
                        disp(getReport(e, 'extended', 'hyperlinks', 'off'));

                        % 中断整个parfor（强行抛错）
                        error('[Interrupt] Parallel execution stopped at individual %d.', popi);
                    end

                end

                % update DE logs
                [bestIndLog, fullPopLog, indFitRobMap, oriPop, oriPopFitness, oriPopRobList] = updateDELogs(bestIndLog, fullPopLog, indFitRobMap, ...
                    bestInd, bestFitness, bestRobList, ...
                    oriPop, oriPopFitness, oriPopRobList, ...
                    crPop, crPopFitness, crPopRobList, geni);

                % termination check
                isFinalGen = (geni == deParams.maxGen);
                isAllRepaired = (sum(bestIndLog(geni).bestRobList > 0) == sortedTS.size);
                if isFinalGen || isAllRepaired
                    % % fitnessMode is cheapincrdis
                    % if contains(fitnessMode, 'cheapincr')
                    %     disp('cheapincr calibration!');
                    %     parfor popi = 1:deParams.popSize
                    %         deFlag = 'calib';
                    %         newFitnessMode = 'expdis';
                    %         altWeights = oriPop(popi, :);
                    %         if strcmp(bmType_, 'simulink')
                    %             assignStructToBase(exConstParams);
                    %             assignStructToBase(exNormParams);
                    %         end
                    % 
                    %         % we need to send bestFitness of last generation
                    %         searchConf = initSearchConf(geni, popi, newFitnessMode, deFlag, altWeights, false, oriPopRobList(:,popi));
                    %         [calibPopFitness(1, popi), calibPopRobList(:, popi)] = fitness(modelInfo, simConf, searchConf, sortedTS);
                    %     end
                    % 
                    %     % find best individual in current generation
                    %     [calibBestInd, calibBestFitness, calibBestRobList] = findBestIndividual(oriPop, calibPopFitness, calibPopRobList);
                    % 
                    %     repTime = toc;
                    %     resDir = fullfile('./results', this.bm, 'DE', sprintf('tops_%d_popSize_%d_gen_%d', this.dim, deParams.popSize, deParams.maxGen));
                    %     if ~exist(resDir, 'dir')
                    %         mkdir(resDir);
                    %     end
                    %     calibResName = [deParams.resNamePrefix, '_geni_', num2str(geni), '_calib.mat'];
                    %     calibFullPath = fullfile(resDir, calibResName);
                    %     save(calibFullPath, "faultType", "mutant", "mutOpMode", "mutOpNoise", "flMode", "spsWeights", "fitnessMode", "deParams", "bestIndLog", 'fullPopLog', "calibBestInd", "calibBestFitness", "calibBestRobList", "calibPopFitness", "calibPopRobList", "repTime");
                    % elseif strcmp(fitnessMode, 'expdis') || contains(fitnessMode, 'expcon')
                        repTime = toc;
                        resDir = fullfile('./results', this.bm, 'DE', sprintf('tops_%d_popSize_%d_gen_%d', this.dim, deParams.popSize, deParams.maxGen));
                        if ~exist(resDir, 'dir')
                            mkdir(resDir);
                        end
                        resName = [deParams.resNamePrefix, '_geni_', num2str(geni), '.mat'];
                        resFullPath = fullfile(resDir, resName);
                        save(resFullPath, "faultType", "mutant", "mutOpMode", "mutOpNoise", "flMode", "spsWeights", "fitnessMode", "deParams", "bestIndLog", 'fullPopLog', "repTime");
                    % end
                    % delete useless checkpoint if exists
                    checkpointResName = [deParams.resNamePrefix, '_checkpoint_geni_*.mat'];
                    delete(checkpointResName);
                    return;
                end

                % save the result every deParams.checkpointStep iterations
                if mod(geni, deParams.checkpointStep) == 0
                    repTime = toc;
                    checkpointResName = [deParams.resNamePrefix, '_checkpoint_geni_', num2str(geni), '.mat'];
                    save(checkpointResName, "faultType", "mutant", "mutOpMode", "mutOpNoise", "flMode", "spsWeights", "fitnessMode", "deParams", 'bestIndLog', 'fullPopLog', "repTime");
                end
            end

            % if the number of the safe traces is less than that before applying the alternative weights
            if sum(bestIndLog(geni).bestRobList > 0) <= sortedTS.sn
                disp('DE fails within maxGen!');
            end
        end

        function [calibBestIndLog, calibFullPopLog] = calibCheapIncr(this, folderPath, deParams, coreNum, exConstParams, exNormParams, calibStep)


            allFiles = dir(fullfile(folderPath, '*.mat'));
            matchedFiles = allFiles(contains({allFiles.name}, 'cheapincr'));

            % start parallel computation
            initParpool(coreNum);

            for fi = 1:numel(matchedFiles)

                fileName = matchedFiles(fi).name;
                filePath = fullfile(folderPath, fileName);
                curRes = load(filePath);

                % sort TS according to the robustness value of each test case
                sortedTS = sortTestSuite(curRes.mutant.mut_TS);

                % define checkpoint
                calibCheckPoint = [1, calibStep:calibStep:deParams.maxGen];
                % in case curStopGen differs from deParams.maxGen
                curStopGen = find(~cellfun(@isempty, {curRes.fullPopLog.pop}), 1, 'last');
                calibCheckPoint = unique([calibCheckPoint, curStopGen]);
                % 在curStopGen之后截断
                calibCheckPoint = calibCheckPoint(calibCheckPoint <= curStopGen);

                % indFitRobMap for acceleration;
                % oriPopFitness and oriPopRoblist to define curCalibPopFitness and curCalibPopRobList
                % calibBestIndLog and calibFullPopLog, final output
                [~, ~, indFitRobMap, oriPopFitness, oriPopRobList, ~, ~, calibBestIndLog, calibFullPopLog] = initDELogs(sortedTS.size, curRes.deParams.popSize, curRes.deParams.maxGen);

                modelInfo = struct();
                modelInfo.bm = this.bm;
                modelInfo.bmType = this.bmType;
                bmType_ = modelInfo.bmType;
                this.mdl_b = curRes.mutant.bug_mdl;
                modelInfo.faultyMdl = this.mdl_b;
                modelInfo.oriWeights = this.weight;
                modelInfo.spsWeights = curRes.spsWeights;

                simConf = struct();
                simConf.T = this.T;
                simConf.Ts = this.Ts;
                simConf.in_name = this.in_name;
                simConf.in_span = this.in_span;
                simConf.phi = this.phi;

                disp('cheapincr calibration!');
                for geni = calibCheckPoint

                    curPop = curRes.fullPopLog(geni).pop;
                    curPopFitness = curRes.fullPopLog(geni).popFitness;
                    curPopRobList = curRes.fullPopLog(geni).popRobList;
                    % 定义空的结构，存储当前一代的所有数据
                    curCalibPopFitness = oriPopFitness;
                    curCalibPopRobList = oriPopRobList;

                    parfor popi = 1:deParams.popSize

                        deFlag = 'calib';
                        fitnessMode = 'calib';
                        % 当前cpu核负责的个体
                        altWeights = curPop(popi, :);
                        % 不精准的fitnessVal, 没算完
                        fitnessVal = curPopFitness(1,popi);
                        % 包含-inf和inf
                        robList = curPopRobList(:,popi);
                        
                        % 先判断是否包含inf或者-inf，如果不需要校正，就跳过。
                        if ~any(isinf(robList))
                            % 收集当前cpu核负责的个体的信息 fitness跟roblist，这就是最终版本了
                            curCalibPopFitness(1,popi) = fitnessVal;
                            curCalibPopRobList(:,popi) = robList;
                        else
                            if strcmp(bmType_, 'simulink')
                                assignStructToBase(exConstParams);
                                assignStructToBase(exNormParams);
                            end

                            searchConf = initSearchConf(geni, popi, fitnessMode, deFlag, altWeights, false, robList);
                            % 反正算出来了，收集当前核负责的个体的信息
                            [curCalibPopFitness(1, popi), curCalibPopRobList(:, popi)] = fitness(modelInfo, simConf, searchConf, sortedTS);
                        end
                    end

                    % 对当前代进行全面的更新，更新字典，calibXXLog系列和当前最好的标定后的calibBestInd,
                    % calibBestFitness, calibBestRobList
                    [calibBestIndLog, calibFullPopLog, indFitRobMap] = updateCalibDELogs(calibBestIndLog, calibFullPopLog, indFitRobMap, ...
                        curPop, curCalibPopFitness, curCalibPopRobList, geni);
                end

                subStr = ['calibStep_', num2str(calibStep), '_calibGen'];
                newFilePath = strrep(filePath, 'calib', subStr);
                fieldsToSave = setdiff(fieldnames(curRes), {'calibPopFitness', 'calibPopRobList', 'calibBestInd', 'calibBestFitness', 'calibBestRobList'});
                save(newFilePath, '-struct', 'curRes', fieldsToSave{:});
                save(newFilePath, 'calibBestIndLog', 'calibFullPopLog', '-append');

            end
        end

        function [bestIndLog, fullPopLog] = randomRepair(this, faultType, mutant, mutOpMode, mutOpNoise, flMode, spsWeights, deParams, repLog_ID, coreNum, exConstParams, exNormParams)
            % randomRepair function aims to repair the model with a set of randomly generated alternative weights.
            %
            % Inputs:
            %   mutant:
            
            % Outputs:
            %   bestInd: the best individual of each generation
           
            % there is a bug! if the safety rate of two individuals are the same, we need to select the one with a greater robustness value sum
            % reset this.dim
            % set a timer
            tic;

            % for random mode, fitness function is not applicable
            fitnessMode = 'expdis';

            this.dim = size(spsWeights, 1);
            this.mdl_b = mutant.bug_mdl;
            % sort TS according to the robustness value of each test case
            sortedTS = sortTestSuite(mutant.mut_TS);

            if strcmp(faultType, 'artificial')
                % reset this.weight (has been corrected in mutation phase)
                [this.weight, ~, ~] = weightSync(this.net, mutant.mut_mode, mutant.mut_op);
            end

            % obtain the lb and ub of the suspicious weights
            [lb, ub] = obtainBound(spsWeights);

            [bestIndLog, fullPopLog, ~, curPopFitness, curPopRobList] = initDELogs(sortedTS.size, deParams.popSize, deParams.maxGen);

            bestInd = [];
            bestFitness = [];
            bestRobList = [];

            modelInfo = struct();
            modelInfo.bm = this.bm;
            modelInfo.bmType = this.bmType;
            bmType_ = modelInfo.bmType;
            modelInfo.faultyMdl = this.mdl_b;  
            modelInfo.oriWeights = this.weight;
            modelInfo.spsWeights = spsWeights;

            simConf = struct();
            simConf.T = this.T;
            simConf.Ts = this.Ts;
            simConf.in_name = this.in_name;
            simConf.in_span = this.in_span;
            simConf.phi = this.phi;
            
            % check if a parallel pool exists
            pool = gcp('nocreate');
            % if a parallel pool exists, delete it
            if ~isempty(pool)
                delete(pool);
            end
            % create a new parallel pool with the desired configuration
            pool = parpool(coreNum);

            % iterate
            for geni = 1:deParams.maxGen

                % initialization, X represents an individual, the column represents the dim of X
                curPop = (ub - lb) .* rand(deParams.popSize, this.dim) + lb;

                popSize = deParams.popSize;
                
                % obtain the fitness value of the initial population
                parfor popi = 1:deParams.popSize
                    deFlag = 'rand';
                    altWeights = curPop(popi, :);
                    if strcmp(bmType_, 'simulink')
                        assignStructToBase(exConstParams);
                        assignStructToBase(exNormParams);
                    end
                    
                    if geni == 1 || isempty(bestFitness)
                        searchConf = initSearchConf(geni, popi, fitnessMode, deFlag, altWeights, true, [], zeros(1, popSize));
                    else
                        searchConf = initSearchConf(geni, popi, fitnessMode, deFlag, altWeights, true, [], bestFitness * ones(1, popSize));
                    end

                    [curPopFitness(1, popi), curPopRobList(:, popi)] = fitness(modelInfo, simConf, searchConf, sortedTS);
                end

                % update random logs
                [bestIndLog, fullPopLog, bestInd, bestFitness, bestRobList] = updateRandomLogs(bestIndLog, fullPopLog, ...
                    bestInd, bestFitness, bestRobList, ...
                    curPop, curPopFitness, curPopRobList, ...
                    geni);

                % termination check
                isFinalGen = (geni == deParams.maxGen);
                isAllRepaired = (sum(bestIndLog(geni).bestRobList > 0) == sortedTS.size);
                if isFinalGen || isAllRepaired                    
          
                    repTime = toc;
                    resDir = fullfile('./results', this.bm, 'random', sprintf('tops_%d_popSize_%d_gen_%d', this.dim, deParams.popSize, deParams.maxGen));
                    if ~exist(resDir, 'dir')
                        mkdir(resDir);
                    end
                    resName = [deParams.resNamePrefix, '_geni_', num2str(geni), '.mat'];
                    resFullPath = fullfile(resDir, resName);
                    save(resFullPath, "faultType", "mutant", "mutOpMode", "mutOpNoise", "flMode", "spsWeights", "fitnessMode", "deParams", "bestIndLog", 'fullPopLog', "repTime");

                    % delete useless checkpoint if exists
                    checkpointResName = [deParams.resNamePrefix, '_checkpoint_geni_*.mat'];
                    delete(checkpointResName);
                    return;
                end

                % save the result every deParams.checkpointStep iterations
                if mod(geni, deParams.checkpointStep) == 0
                    repTime = toc;
                    checkpointResName = [deParams.resNamePrefix, '_checkpoint_geni_', num2str(geni), '.mat'];
                    save(checkpointResName, "faultType", "mutant", "mutOpMode", "mutOpNoise", "flMode", "spsWeights", "fitnessMode", "deParams", 'bestIndLog', 'fullPopLog', "repTime");
                end
            end

            % if the number of the safe traces is less than that before applying the alternative weights
            if sum(bestRobList{1, geni} > 0) <= sortedTS.sn
                disp('DE fails within maxGen!');
            end
        end

        function [fitness, rob] = validatePatch(this, mutant, alt_weight)
            % validateInd function can recheck the individual obtained by AutoPatch
            %
            % Inputs:
            %   mutant:
            %   alt_weight: the individual searched by AutoPatch
            % Outputs:
            %   fitness: fitness value
            %   rob: robustness value

            [y, curRobList] = fitness(mdl_b, this.T, this.Ts, this.in_name, this.in_span, this.phi, this.weight, alt_weight, sps_weight_info, sortedTS, geni, popi, fitnessMode, de_flag);

        end
    end
end
