function [actState] = MI(colNeuronOut, deltaT)
% MI function implements Monotonic Increase Neuron Activation (MI) Criterion and
% returns the activation state of each neuron.
%
% Input:
%   colNeuronOut: the output of each neuron at each inference during a system execution (in columns, each row refers an inference)
%   deltaT: time interval
% Output:
%   actState: a cell array recording the number of activations of each neuron during a system execution

% frameNum: the number of inferences; hLNum: the number of hidden layers
[frameNum, hLNum] = size(colNeuronOut);

% record the number of activations of each neuron during a system execution
actState = cell(1, hLNum);

% initialize actState
for li = 1:hLNum
    actState{1,li} = zeros(size(colNeuronOut{1,li}));
end

tempActState = actState;

for fi = 2:frameNum
    for li = 1:hLNum
        incPos = (colNeuronOut{fi,li} > colNeuronOut{fi-1,li});
        % tempActState records the accumulated time interval
        tempActState{1,li}(incPos) = tempActState{1,li}(incPos) + 1;

        if fi == frameNum
            validIdx = (incPos == 1 & tempActState{1,li} >= deltaT);
            actState{1,li}(validIdx) = actState{1,li}(validIdx) + 1;
        end

        decPos = (colNeuronOut{fi,li} <= colNeuronOut{fi-1,li});
        % decPos and tempActState >= deltaT
        validIdx = find(decPos & tempActState{1,li} >= deltaT);
        actState{1,li}(validIdx) = actState{1,li}(validIdx) + 1;

        % reset decPos
        tempActState{1,li}(decPos) = 0;
    end
end
end