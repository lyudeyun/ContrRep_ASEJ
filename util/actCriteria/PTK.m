function [actState] = PTK(colNeuronOut, deltaT, k)
% PTK function implements Persistent Top-k Neuron Activation (PTK) Criterion and
% returns the activation state of each neuron.
%
% Input:
%   colNeuronOut: the output of each neuron at each inference during a system execution (in columns, each row refers an inference)
%   deltaT: time interval
%   k: Topk value among all the neurons at ith layer topk neurons of each layer
% Output:
%   actState: a cell array recording the number of activations of each neuron during a system execution

% frameNum: the number of inferences; hLNum: the number of hidden layers
[frameNum, hLNum] = size(colNeuronOut);

% record the number of activations of each neuron during a system execution
actState = cell(1,hLNum);
% initialize actState
for li = 1:hLNum
    actState{1,li} = zeros(size(colNeuronOut{1,li}));
end

tempActState = actState;

for fi = 1:frameNum
    for li = 1:hLNum
        layerNeuronOut = colNeuronOut{fi,li};
        [~, idx] = sort(layerNeuronOut, 'descend');
        for i = 1:k
            neuronIdx = idx(i);
            if colNeuronOut{fi,li}(neuronIdx) == 0
                break;
            end
            tempActState{1, li}(neuronIdx) = tempActState{1, li}(neuronIdx) + 1;
        end
        
        goodPos = (tempActState{1,li} >= deltaT & (colNeuronOut{fi,li} < layerNeuronOut(idx(k)) | fi == frameNum));
        actState{1,li}(goodPos) = actState{1,li}(goodPos) + 1;
        tempActState{1,li}(goodPos) = 0;

        badPos = (tempActState{1,li} < deltaT & colNeuronOut{fi,li} <= layerNeuronOut(idx(k)));
        tempActState{1,li}(badPos) = 0;
    end
end
end