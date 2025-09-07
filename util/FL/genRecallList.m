function [recallList] = genRecallList(sortedSpsWeightList, mut_op)
% genRecallList function returns recallList.
%
% Inputs:
%   sortedSpsWeightList: sorted suspicious neuron list
%   mut_op: mutated neurons
% Outputs:
%   recallList:
%   MUT1: [0,1];
%   MUT2: [0,1/2,1];
%   MUT3: [0,1/3,2/3,1];
%   MUT4: [0,1/4,2/4,3/4,1];
%   MUT5: [0,1/5,2/5,3/5,4/5,1];

spsWeightNum = size(mut_op,1);
weightNum = size(sortedSpsWeightList,1);

recallList = zeros(weightNum,1);

for topsi = 1:weightNum
    [detWeight, ~, ~] = intersect(sortedSpsWeightList(1:topsi,:), mut_op, 'rows');
    recallList(topsi,1) = size(detWeight,1)/spsWeightNum;
end

end