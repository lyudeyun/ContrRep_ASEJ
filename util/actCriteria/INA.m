function [actState] = INA(colNeuronOut, th)
% INA function implements Instant Neuron Activation (INA) Criterion and
% returns the activation state of each neuron.
%
% Input:
% colNeuronOut: the output of each neuron at each inference during a system execution (in columns, each row refers an inference)
% th: activation threshold
% Output:
% actState: a cell array recording the number of activations of each neuron during a system execution

% frameNum: the number of inferences; hLNum: the number of hidden layers
[frameNum, hLNum] = size(colNeuronOut);

% record the number of activations of each neuron during a system execution
actState = cell(1,hLNum);
% initialize actState
for li = 1:hLNum
    actState{1,li} = zeros(size(colNeuronOut{1,li}));
end

emptyActState = actState;

% obtain the activation state of each neuron during a system execution
for fi = 1:frameNum
    % reset tempActState
    tempActState = emptyActState;
    for li = 1:hLNum
        tempActState{1,li}((colNeuronOut{fi,li} > th)) = 1;
        actState{1,li} = actState{1,li} + tempActState{1,li};
    end
end
end