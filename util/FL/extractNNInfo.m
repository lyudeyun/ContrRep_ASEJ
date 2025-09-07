function [nnType, nnStru, hLNum, weight, bias, minW, maxW] = extractNNInfo(bm, net, nnStru)
%  EXTRACTNNINFO extracts structural and parameter information from a trained neural network.
%
% Inputs:
%   bm       - Current benchmark
%   net      - A trained neural network from MATLAB's Deep Learning Toolbox
%   nnStru   - nn structure
%
% Outputs:
%   nnType   - Type of the neural network (e.g., 'FFNN', 'LRNN')
%   nnStru   - A vector specifying the structure of the network, including the output layer
%   hLNum    - Number of hidden layers (excluding the output layer)
%   weight   - A cell array where each element contains the weight matrix of a corresponding layer in the network
%   bias     - A cell array where each element contains the bias vector of a corresponding layer in the network
%   minW     - Minimum weight value
%   maxW     - Maximum weight value

switch net.name
    case 'Feed-Forward Neural Network'
        nnType = 'FFNN';
        weight = cell(1, net.numLayers);
        bias = cell(1, net.numLayers);
        hLNum = net.numLayers - 1;

        for li = 1:net.numLayers
            if li == 1
                weight{1,li} = net.IW{1,1};
                [li_row, ~] = size(net.IW{1,1});
                if nnStru(1,li) ~= li_row
                    error('Structure mismatch between nn_stru and nn file!');
                end
            else
                weight{1,li} = net.LW{li,li-1};
                % the number of neurons in the li th layer
                [li_row, ~] = size(net.LW{li,li-1});
                if nnStru(1,li) ~= li_row
                    error('Structure mismatch between nn_stru and nn file!');
                end
            end
            bias{1,li} = net.b{li};
        end
    case 'Layer Recurrent Neural Network'
        nnType = 'LRNN';
        weight = cell(2, net.numLayers);
        bias = cell(1, net.numLayers);
        for li = 1:net.numLayers
            if li == 1
                % input weight for external input
                weight{1,li} = net.IW{1,1};
                % layer weight for hidden state
                weight{2,li} = net.LW{1,1};
                %
            elseif li > 1 && li < layer_num + 1
                weight{1,li} = net.LW{li,li-1};
                weight{2,li} = net.LW{li,li};
            else
                % output layer
                weight{1,li} = net.LW{li,li-1};
            end
            bias{1,li} = net.b{li};
        end
    otherwise
        % currently, SpectAcle only supports FFNN and LRNN.
        error('Check the type of the neural network!');
end

weightCopy = weight;
% There is an outlier in this neural network. it was not considered when
% calculating the range. 
if strcmp(bm, 'AFC') && isequal(nnStru, [15,15,15,15,1])
    weightCopy{1,3}(15, 8) = 0;
end

% obtain the range of NN controller' weights
if strcmp(nnType, 'FFNN')
    allWeights = [];
    for li = 2:hLNum
        allWeights = [allWeights; weightCopy{1,li}(:)];
    end
elseif strcmp(nnType, 'LRNN')
    % still exists bug, but enough for SC_RNN
    allWeights = [];
    for li = 2:hLNum
        % weight_cp{2,li} -> bug
        allWeights = [allWeights; weightCopy{2,li}(:)];
    end
end
minW = min(allWeights);
maxW = max(allWeights);

end



