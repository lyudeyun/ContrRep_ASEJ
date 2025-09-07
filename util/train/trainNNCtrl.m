function [mdlName] = trainNNCtrl(template, oldVersion, specName, XTrain, YTrain, nnType, delay, nnStru, algo, epoch, isNor, sgy)
% train NN controllers according to different configurations
%
% Inputs:
%   template:
%   oldVersion:
%   specName:
%   XTrain:
%   YTrain:
%   nnType: FFNN, LRNN
%   delay: layerDelays for LRNN
%   nnStru: NN structure
%   algo: training algorithm
%   date: training date
%   isNor: normalized or not
%   sgy: strategy
% Outputs:
%   nnCtrName: NN controller
%   nnConfName:

if isNor == 1
    norFlag = 'Nor';
else
    norFlag = 'UnNor';
end

dateStr = datestr(datetime('today'), 'yyyymmdd');


if strcmpi(nnType, 'ffnn')
    hiddenLayers = nnStru;
    ffnn = feedforwardnet(hiddenLayers, algo);

    % ffnnNet.trainFcn = 'trainscg';
    for i = 1:length(hiddenLayers)
        % type 'help nntransfer'
        ffnn.layers{i}.transferFcn = 'poslin';
    end
    ffnn.layers{length(hiddenLayers)+1}.transferFcn = 'purelin';

    % for input and ouput, mapminmax Min-Max normalization,etc.
    ffnn.inputs{1}.processFcns = {};
    ffnn.outputs{length(hiddenLayers)+1}.processFcns = {};

    ffnn = configure(ffnn,XTrain,YTrain);
    ffnn.plotFcns = {'plotperform','plottrainstate',...
        'ploterrhist','plotregression','plotresponse'};

    [xs,xi,ai,ts] = preparets(ffnn,XTrain,YTrain);

    ffnn.trainParam.epochs = epoch;       % maximum number of training
    ffnn.trainParam.min_grad = 1e-10;    % minimal gradient
    % ffnnNet.trainParam.goal = 0.1;        % minimum target error/required accurracy
    % ffnnNet.trainParam.show = 20;         % display frequency
    % ffnnNet.trainParam.mc = 0.95;         % momentum constant
    % ffnnNet.trainParam.lr = 0.05;         % learning rate
    % ffnnNet.trainParam.time = 10000;      % maxnimum training time
    ffnn.trainParam.max_fail = 6;       % minimal failed times of training failures

    [ffnn,~] = train(ffnn,xs,ts,xi,ai,'showResources','yes','useParallel','yes','useGPU','no');

    % Y = ffnn(xs,xi,ai);
    % perf = perform(ffnn,Y,ts);
    % err = cell2mat(Y)-cell2mat(ts);
    % plot(error);

    if sgy == 0
        nnBlockName = specName + "_F_" + algo + "_" + strjoin(string(nnStru), "_")  + "_controller_"  + "ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
        nnConfName = specName + "_F_" + algo + "_" + strjoin(string(nnStru), "_") + "_config_" + "ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
    else
        nnBlockName = specName + "_F_" + algo + "_" + strjoin(string(nnStru), "_")  + "_st_" + sgy + "_controller_" + "ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
        nnConfName = specName + "_F_" + algo + "_" + strjoin(string(nnStru), "_") + "_st_" + sgy + "_config_" + "ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
    end

    nnCtrBlock = gensim(ffnn, 'Name', nnBlockName);
    save_system(nnCtrBlock);
    close_system(nnCtrBlock);

    net = ffnn;
    save(strjoin(nnConfName, ".mat"),'net');

elseif strcmpi(nnType, 'lrnn')
    % Create a L-RNN network
    layerDelays = delay;
    hiddenLayers = nnStru;
    % 'trainlm' is default fucntion, but trainscg' is the only function that supports GPU
    % https://www.mathworks.com/help/deeplearning/ug/choose-a-multilayer-neural-network-training-function.html
    lrnn = layrecnet(layerDelays,hiddenLayers,algo);

    lrnn.inputs{1}.processFcns = {};
    lrnn.outputs{length(hiddenLayers)+1}.processFcns = {};
    [Xs,Xi,Ai,Ts] = preparets(lrnn, XTrain,YTrain);
    % if you don't have a GPU, you can comment out 'UseGPU', 'yes'
    lrnn.trainParam.epochs = epoch;     % maximum number of training
    lrnn.trainParam.max_fail = 6;

    lrnn = train(lrnn,Xs,Ts,Xi,Ai,'showResources','yes','UseParallel','yes','UseGPU','no');
    % Y = lrnn(Xs,Xi,Ai);
    % perf = perform(lrnn,Y,Ts);
    % err = cell2mat(Y)-cell2mat(Ts);
    % plot(error_lrnn);

    if sgy == 0
        nnBlockName = specName + "_LR_" + algo + "_" + strjoin(string(delay), "_") + "_" + strjoin(string(nnStru), "_") + "_controller_" + "_ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
        nnConfName = specName + "_LR_" + algo + "_" + strjoin(string(delay), "_") + "_" + strjoin(string(nnStru), "_") + "_config_" + "_ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
    else
        nnBlockName = specName + "_LR_" + algo + "_" + strjoin(string(delay), "_") + "_" + strjoin(string(nnStru), "_") + "_st_" + sgy + "_controller_" + "_ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
        nnConfName = specName + "_LR_" + algo + "_" + strjoin(string(delay), "_") + "_" + strjoin(string(nnStru), "_") + "_st_" + sgy + "_config_" + "_ep_" + string(epoch) + "_" + string(norFlag) + "_" + dateStr;
    end

    nnCtrBlock = gensim(lrnn, 'Name', nnBlockName);
    save_system(nnCtrBlock);
    close_system(nnCtrBlock);
    net = lrnn;
    save(strjoin(nnConfName, ".mat"),'net');
else
    error('try again');
end


mdlName = [char(specName), '_', nnType, '_', algo, '_', char(strjoin(string(nnStru), '_')), '_ep_', num2str(epoch), '_', norFlag, '_', dateStr];

% obtain the absolute path of current template
tempPath = which([template, '.slx']);

tempCopy = [template, '_Target.slx'];
% copy the model as the model to be modified
copyfile(tempPath, tempCopy);

nnBlockName = char(nnBlockName);

open_system(nnBlockName);

srcPath = [nnBlockName, '/Feed-Forward Neural Network'];

% left is the source model, right is the destination model
if contains(specName, 'ACC')
    pil_block_replace(srcPath, [template, '_Target','/Feed-Forward Neural Network']);
elseif contains(specName, 'AFC')
    pil_block_replace(srcPath, [template, '_Target','/Air Fuel Control Model 1/Feed-Forward Neural Network']);
end

set_param(tempCopy(1:end-4), 'Dirty', 'on');
save_system(tempCopy(1:end-4), [], 'OverwriteIfChangedOnDisk', true);

% save the destination model with the new NN controller as the 2021a version
if oldVersion ~= version('-release')
    save_system(tempCopy(1:end-4), [mdlName,'.slx'], "ExportToVersion", oldVersion);
else % no need to export 
    save_system(tempCopy(1:end-4), [mdlName,'.slx']);
end

% close and delete the copy of template model
close_system(tempCopy(1:end-4));
delete(tempCopy);
delete(['*.',oldVersion]);

newFolder(mdlName);
movefile([nnBlockName,'.slx'], mdlName);
movefile([char(nnConfName), '.mat'], mdlName);
movefile([mdlName, '.slx'], mdlName);
delete('*.slx.autosave');
end