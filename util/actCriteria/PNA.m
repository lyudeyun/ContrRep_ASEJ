function [actState] = PNA(colNeuronOut, th, deltaT)
% PNA function implements Persistent Neuron Activation (PNA) Criterion and
% returns the activation state of each neuron.
%
% Input:
%   colNeuronOut: the output of each neuron at each inference during a system execution (in columns, each row refers an inference)
%   th: activation threshold
%   deltaT: time interval
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

% obtain the activation state of each neuron during a system execution
for fi = 1:frameNum
    for li = 1:hLNum
        % if a neuron is activated at this timestamp, its time interval will be incremented by 1.
        actPos = (colNeuronOut{fi,li} > th);
        tempActState{1,li}(actPos) = tempActState{1,li}(actPos) + 1;
        % tempActState >= deltaT and this neuron is not activated at this timestamp
        goodPos = (tempActState{1,li} >= deltaT & (colNeuronOut{fi,li} <= th | fi == frameNum));
        actState{1,li}(goodPos) =  actState{1,li}(goodPos) + 1;
        tempActState{1,li}(goodPos) = 0;
        % tempActState < deltaT and this neuron is not activated at this timestamp
        badPos = (tempActState{1,li} < deltaT & colNeuronOut{fi,li} <= th);
        tempActState{1,li}(badPos) = 0;
    end
end
end