function [testSuite] = genTestSuite(mdlInfo, simConf, tsInfo, exConstParams, exNormParams)


[nnType, nnStru, hLNum, weight, bias, minW, maxW] = extractNNInfo(mdlInfo.bm, mdlInfo.net, mdlInfo.nnStru);

testCases(tsInfo.testCaseNum, 1) = struct( ...
    'sysInputs', [], ...
    'nnInputs', [], ...
    'nnOutputs', [], ...
    'expNeuronOut', [], ...
    'rob', [], ...
    'taus', []);

parfor tci = 1:tsInfo.testCaseNum

    assignStructToBase(exConstParams);
    assignStructToBase(exNormParams);

    mdlName = ['mdl_i_', num2str(tci)];
    mdlPath = fullfile(pwd, [mdlName, '.slx']);

    % Close if model already loaded
    if bdIsLoaded(mdlName), bdclose(mdlName); end
    if isfile(mdlPath), delete(mdlPath); end

    modelPath = which([mdlInfo.mdl, '.slx']);
    copyfile(modelPath, [mdlName, '.slx']);

    Br = BreachSimulinkSystem(mdlName);
    Br.Sys.tspan = 0:simConf.Ts:simConf.T;

    in_span = cell2mat(simConf.in_span);
    if isscalar(unique(in_span))
        cp = simConf.T/in_span(1);
    else
        cp = simConf.T./in_span;
    end

    sysInNum = numel(simConf.in_name);
    sysInputs = cell(sysInNum, 1);
    for in_i = 1:sysInNum
        in_range_i = simConf.in_range{1,in_i};
        sysInputs{in_i} = unifrnd(in_range_i(1,1), in_range_i(1,2), 1, cp);
    end

    [rob, Br, taus, nnInputs, nnOutputs] = signalDiagnosis(mdlInfo.bm, mdlName, mdlInfo.D_run, mdlInfo.is_nor, Br, simConf.T, simConf.Ts, simConf.in_name, in_span, simConf.icc_name, simConf.ic_const, simConf.ics_name, simConf.oc_name, simConf.phi_str, sysInputs);

    if rob < 0
        disp(rob);
    end
    [~, neuronOut] = weightToNeuron(mdlInfo.net, nnStru, weight, bias, nnInputs);

    frameNum = numel(neuronOut);  % 自动获取 neuronOut 的长度
    hLNum = numel(neuronOut{1}) - 1;
    expNeuronOut = cell(frameNum, hLNum);  % 假设每个元素始终是 1×4 cell


    for i = 1:frameNum
        expNeuronOut(i, :) = neuronOut{i}(1:hLNum);  % 将每个 1×4 cell 拍平为一行
    end

    testCases(tci).sysInputs = sysInputs;
    testCases(tci).nnInputs = nnInputs;
    testCases(tci).nnOutputs = nnOutputs;
    testCases(tci).expNeuronOut = expNeuronOut;
    testCases(tci).rob = rob;
    testCases(tci).taus = taus;

end

testSuite.sn = sum([testCases.rob] > 0);
testSuite.size = tsInfo.testCaseNum;
testSuite.testCases = testCases;
disp(testSuite.sn);

save(tsInfo.tsName, 'testSuite');

end

% [TTKVal, actState] = TTK(neuronOutExpanded, 5, 4);


function [rob, Br, taus, nnInputs, nnOutputs] = signalDiagnosis(bm, mdl, D_run, is_nor, Br, T, Ts, in_name, in_span, icc_name, ic_const, ics_name, oc_name, phiStr, sysInputs)
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

phi = STL_Formula('phi',phiStr);

[rob, Br] = calRob(mdl, Br, T, Ts, in_name, in_span, phi, sysInputs);

% extract ic signal and oc signal for forward impact analysis
% (analysis the impact of a weight to the final result)
nnInputs = sigMatch(Br, [icc_name, ics_name]);
nnOutputs = sigMatch(Br, oc_name);

if is_nor == 1
    x_gain = D_run.ps_x.gain;
    x_gain = diag(x_gain);
    x_offset = D_run.ps_x.xoffset;
    nnInputs = nnInputs - x_offset;
    nnInputs = x_gain * nnInputs;

    y_gain = D_run.ps_y.gain;
    y_offset = D_run.ps_y.xoffset;
    nnOutputs = nnOutputs/y_gain;
    nnOutputs = nnOutputs + y_offset;
end

% calculate the tau_s according to the given specification
if rob > 0
    taus = T;
    return;
end

[taus, validVioIdx] = extractTaus(bm, mdl, T, Ts, Br, sysInputs, phiStr);


% extract the input and output signals of nn controller in the interval [0, tau_s]
nnInputs = nnInputs(:,1:validVioIdx(1,1));
nnOutputs = nnOutputs(:,1:validVioIdx(1,1));
end


function [weight2Neuron, neuronOut] = weightToNeuron(net, nnStru, weight, bias, input)
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
    neuronOutSnapShot = initVar(net, nnStru, 'neuronOutSnapShot');
    % record the impact of a weight of a neuron to the output of this neuron at a certain frame
    weight2NeuronSnapShot = initVar(net, nnStru, 'weight2NeuronSnapShot');
    for i = 1: net.numLayers
        if i == 1
            transFcn = net.layers{i}.transferFcn();
            transFcn = str2func(transFcn);
            neuronOutSnapShot{1,1} = transFcn(weight{1,1} * input(:,j) + bias{1, i});
            % calculate the impact of an input weight of a neuron to the output of this neuron
            for ni = 1: nnStru(1,i)
                % the absolute sum of current neuron
                weightoutSum = abs(weight{1,1}(ni,:)) * abs(input(:,j));
                % calculate weight2NeuronSnapShot one by one
                for wi = 1:row
                    weight2NeuronSnapShot{1,1}(ni,wi) = abs(weight{1,1}(ni,wi)) * abs(input(wi,j))/weightoutSum;
                end
            end
        else
            transFcn = net.layers{i}.transferFcn();
            transFcn = str2func(transFcn);
            neuronOutSnapShot{1,i} = transFcn(weight{1,i} * neuronOutSnapShot{1,i-1} + bias{1, i});
            % calculate the impact of a layer weight of a neuron to the output of this neuron.
            for ni = 1: nnStru(1,i)
                % the absolute sum of current neuron
                weightoutSum = abs(weight{1,i}(ni,:)) * abs(neuronOutSnapShot{1,i-1});
                % calculate weight2NeuronSnapShot one by one
                for wi = 1:nnStru(1,i-1)
                    weight2NeuronSnapShot{1,i}(ni,wi) = abs(weight{1,i}(ni,wi)) * abs(neuronOutSnapShot{1,i-1}(wi,1))/weightoutSum;
                end
            end
        end
    end
    neuronOut{end+1} = neuronOutSnapShot;
    weight2Neuron{end+1} = weight2NeuronSnapShot;
end
end