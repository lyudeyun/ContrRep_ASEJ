       function [nn_ctrl] = trainNN(this, dataset, nn_type, nn_strc, is_prep)
            % train nn controller
            %
            % Inputs:
            %   nn_type: FFNN, NARX, RNN
            %   nn_strc: nn strcuture
            %   is_prep: is it pre-processed
            % Outputs:
            %   nn_ctrl: neural network controller

            % Load corresponding trainset and ps_data(ps_x,ps_y)
            % ps_x and ps_y are used to restore the input and output by constructing the MATLAB FUNCTION block
            % ps_data: scale and offset information generated from normalization process
            % https://www.mathworks.com/help/deeplearning/ref/mapminmax.html
            if is_prep == 1 || is_prep == "true"
                [XTrain,YTrain,ps_x,ps_y] = preprocess(dataset);
            end

            if nn_type == "NARX" || nn_type == "narx"
                % Create a NARX network, the default is open-loop state.
                inputDelays = 1:2;
                feedbackDelays = 1:2;
                % Here the hiddenLayerSize is 10 means there is only a single hiddenLayer
                hiddenLayers = [10,5];
                narx_net = narxnet(inputDelays,feedbackDelays,hiddenLayers,'open','trainlm');
                narx_net.divideFcn = '';
                % Set trainParameters
                narx_net.trainParam.min_grad = 1e-10;
                narx_net.trainParam.epochs = 1000;     % maximum number of training
                narx_net.trainParam.max_fail = 10;     % minimal failed times of training failures
                % narx_net.trainParam.time = 10000;    % maxnimum training time
                % narx_net.trainParam.goal = 0.1;      % minimum target error/required accurracy
                % narx_net.trainParam.show = 20;       % display frequency
                % narx_net.trainParam.mc = 0.95;       % momentum constant
                % narx_net.trainParam.lr=0.05;         % learning rate
                % narx_net.perFromFcn='sse';           % performance function, 'sse':The sum of squared errors

                narx_net.inputs{1}.processFcns = {};
                narx_net.outputs{length(hiddenLayers)+1}.processFcns = {};

                [xs,xi,ai,ts] = preparets(narx_net,XTrain,{},YTrain);
                [narx_net,tr] = train(narx_net,xs,ts,xi,'showResources','yes','UseParallel','yes','UseGPU','yes');
                yp = narx_net(xs,xi,ai);
                perf = perform(narx_net,ts,yp);
                error_narx = cell2mat(yp)-cell2mat(ts);
                plot(error_narx);
                % gsubtract(a,b) takes two matrices or cell arrays, and subtracts them in an element-wise manner.
                % e = gsubtract(t,y);

                % Convert the network to closed loop.
                narx_net_closed = closeloop(narx_net);
                % Prepare test data and simulate the network’s closed loop response.
                [xs_c,xi_c,ai_c,ts_c] = preparets(narx_net_closed,XTest,{},YTest);
                yp_c = narx_net_closed(xs_c,xi_c,ai_c);
                perf_closed = perform(narx_net_closed,ts_c,yp_c);


                %     % 从网络中删除一个延迟，以提前一个时间步获得预测。
                %     narx_net_delay = removedelay(narx_net_closed);
                %     [xs_d,xi_d,ai_d,ts_d] = preparets(narx_net_delay, XTest,{},YTest);
                %     yp_d = narx_net_delay(xs_d,xi_d,ai_d);
                %     perf_delay = perform(narx_net_delay,ts_d,yp_d);

            elseif nn_type == "LRNN" || nn_type == "lrnn"
                % Create a L-RNN network
                layerDelays = 1:2;
                hiddenLayers = [10,10];
                % 'trainlm' is default fucntion, but trainscg' is the only function that supports GPU
                % https://www.mathworks.com/help/deeplearning/ug/choose-a-multilayer-neural-network-training-function.html
                lrnn_net = layrecnet(layerDelays,hiddenLayers,'trainscg');
                lrnn_net.inputs{1}.processFcns = {};
                lrnn_net.outputs{length(hiddenLayers)+1}.processFcns = {};
                [Xs,Xi,Ai,Ts] = preparets(lrnn_net, XTrain,YTrain);
                % if you don't have a GPU, you can comment out 'UseGPU', 'yes'
                lrnn_net = train(lrnn_net,Xs,Ts,Xi,Ai,'showResources','yes','UseParallel','yes','UseGPU','yes');
                Y = lrnn_net(Xs,Xi,Ai);
                perf_lrnn = perform(lrnn_net,Y,Ts);
                block_name = [benchmark,'_LRNN'];
                error_lrnn = cell2mat(Y)-cell2mat(Ts);
                plot(error_lrnn);
                gensim(narx_net_closed, 'Name', block_name);
                % FFNN
            elseif nn_type == "FFNN" || nn_type == "ffnn"
                hiddenLayers = [30,30,30,30];
                ffnn_net = feedforwardnet(hiddenLayers);
                ffnn_net.trainFcn = 'trainscg';
                for i = 1:length(hiddenLayers)
                    % type 'help nntransfer'
                    ffnn_net.layers{i}.transferFcn = 'poslin';
                end
                ffnn_net.layers{length(hiddenLayers)+1}.transferFcn = 'purelin';

                % % for input and ouput, mapminmax Min-Max normalization,etc.
                ffnn_net.inputs{1}.processFcns = {};
                ffnn_net.outputs{length(hiddenLayers)+1}.processFcns = {};

                ffnn_net = configure(ffnn_net,XTrain,YTrain);
                ffnn_net.plotFcns = {'plotperform','plottrainstate',...
                    'ploterrhist','plotregression','plotresponse'};

                [xs,xi,ai,ts] = preparets(ffnn_net,XTrain,YTrain);

                ffnn_net.trainParam.epochs = 1000;       % maximum number of training
                ffnn_net.trainParam.min_grad = 1e-10;  % minimal gradient
                %                 ffnn_net.trainParam.goal = 0.1;        % minimum target error/required accurracy
                %                 ffnn_net.trainParam.show = 20;         % display frequency
                %                 ffnn_net.trainParam.mc = 0.95;         % momentum constant
                %                 ffnn_net.trainParam.lr = 0.05;           % learning rate
                %                 ffnn_net.trainParam.time = 10000;              % maxnimum training time
                %                 ffnn_net.trainParam.max_fail = 6;        % minimal failed times of training failures

                [ffnn_net,~] = train(ffnn_net,xs,ts,xi,ai,'showResources','yes','useParallel','yes','useGPU','yes');
                Y = ffnn_net(xs,xi,ai);
                perf_ffnn = perform(ffnn_net,Y,ts);
                block_name = [benchmark,'_FFNN'];
                error_ffnn = cell2mat(Y)-cell2mat(ts);
                plot(error_ffnn);
                gensim(ffnn_net, 'Name', block_name);
            else
                error('try again');
                return;
            end
        end