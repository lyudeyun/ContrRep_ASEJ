function var = initVar(net, nnStru, varName)
% initVar function returns the initialized variable based on the given variable name
%
% Inputs
%   net     : A trained neural network from MATLAB's Deep Learning Toolbox
%   nnStru  : A vector specifying the structure of the network, including the output layer
%   varName : The name of the variable to initialize
% Outputs
%   var     : The initialized variable

allLNum = numel(nnStru);
% consider the output layer
hLNum = allLNum - 1;

switch varName

    case 'neuronOutSnapShot'
        var = cell(1,allLNum);
        for li = 1:allLNum
            var{li} = zeros(nnStru(li),1);
        end

    case 'neuron2OutSnapShot'
        var = cell(1,hLNum);
        for li = 1:hLNum
            var{li} = zeros(nnStru(li),1);
        end

    case {'weight2NeuronSnapShot', 'weight2OutSnapShot', 'weight2OutSnapShotBinary', 'spsScore'}
        var = cell(1,allLNum);
        var{1} = zeros(size(net.IW{1,1}));
        for li = 2:allLNum
            var{li} = zeros(size(net.LW{li,li-1}));
        end

    case 'exeSpectrum'
        var = cell(1,allLNum);
        var{1} = arrayfun(@(~) zeros(1,4), net.IW{1,1}, 'UniformOutput', false);
        for li = 2:allLNum
            var{li} = arrayfun(@(~) zeros(1,4), net.LW{li,li-1}, 'UniformOutput', false);
        end

        % ad-hoc for SC_R
    case {'rnnWeight2OutSnapShot', 'rnnWeight2OutSnapShotBinary', 'rnnSpsWeight'}
        var = cell(2,allLNum);
        var{1,1} = zeros(net.IW{1,1});
        var{2,1} = zeros(net.LW{1,1});
        for li = 2:allLNum
            var{1,li} = zeros(size(net.LW{li,li-1}));
        end

    case 'rnnExeSpectrum'
        var = cell(2,allLNum);
        var{1,1} = arrayfun(@(~) zeros(1,4), net.IW{1,1}, 'UniformOutput', false);
        var{2,1} = arrayfun(@(~) zeros(1,4), net.LW{1,1}, 'UniformOutput', false);
        for li = 2:allLNum
            var{1,li} = arrayfun(@(~) zeros(1,4), net.LW{li,li-1}, 'UniformOutput', false);
        end

    otherwise
        error('Check the name of variable!');
end
end