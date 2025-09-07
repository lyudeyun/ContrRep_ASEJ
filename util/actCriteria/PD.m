function [actState] = PD(colNeuronOut, diffTh, deltaT)
% PD function implements Positive Differential Neuron Activation (PD) Criterion and
% returns the activation state of each neuron.
%
% Input:
%   colNeuronOut: the output of each neuron at each inference during a system execution (in columns, each row refers an inference)
%   diffTh: differential activation threshold
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

for fi = 1:frameNum
    for li = 1:hLNum
        colNeuronOut{fi,li} = colNeuronOut{fi,li}';
    end
end

% expand cell to matrix and arrage horizontally
matNeuronOut = cell2mat(colNeuronOut);

% initialize actState in a matrix form
matActState = zeros(size(matNeuronOut(1,:)));

for fi = deltaT+1:frameNum
    tempMatNeuronOut = matNeuronOut(fi-deltaT:fi,:);
    [maxArray, maxIndex] = max(tempMatNeuronOut);
    [minArray, minIndex] = min(tempMatNeuronOut);
    goodPos = (maxArray - minArray > diffTh) & (maxIndex > minIndex);
    matActState(goodPos) = matActState(goodPos) + 1;
end

idx = 0;
for li = 1:hLNum
    layerNeuronNum = numel(actState{1,li});
    actState{1,li} = matActState(1,idx+1:idx+layerNeuronNum)';
    idx = idx + layerNeuronNum;
end
end