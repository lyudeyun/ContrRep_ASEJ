function [actState] = MD(colNeuronOut, deltaT)
% MD function implements Monotonic Decrease Neuron Activation (MD) Criterion and
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
        decPos = (colNeuronOut{fi,li} < colNeuronOut{fi-1,li});
        % tempActState records the accumulated time interval
        tempActState{1,li}(decPos) = tempActState{1,li}(decPos) + 1;

        if fi == frameNum
            validIdx = (decPos == 1 & tempActState{1,li} >= deltaT);
            actState{1,li}(validIdx) = actState{1,li}(validIdx) + 1;
        end

        incPos = (colNeuronOut{fi,li} >= colNeuronOut{fi-1,li});
        % incPos and tempActState >= deltaT
        validIdx = find(incPos & tempActState{1,li} >= deltaT);
        actState{1,li}(validIdx) = actState{1,li}(validIdx) + 1;

        % reset incPos
        tempActState{1,li}(incPos) = 0;
    end
end
end