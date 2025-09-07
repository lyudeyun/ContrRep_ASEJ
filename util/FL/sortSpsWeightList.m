function [sortedSpsWeightList] = sortSpsWeightList(spsWeightList, mode)
% SORTSPSWEIGHTLIST Sorts suspicious weights by suspiciousness scores (5th column), with optional tie shuffling.
%
% Inputs
%   spsWeightList: [li, i, j, oriVal, spsScore]
%   mode: 'fixed'/'random'
%
% Output
%   sortedSpsWeightList: sorted suspicious weight list

% replace NaN with 0
spsWeightList(isnan(spsWeightList)) = 0;

% sort descending by suspiciousness scores (5th column)
colIdx = 5;
[sortedSpsWeightList, ~] = sortrows(spsWeightList, -colIdx);

if strcmp(mode, 'fixed')
    return;
end

% save current RNG state for later restoration
oldRng = rng;
% use a fixed seed to make sortedSpsWeightList reproducible
seed = 0;
% seed the RNG for deterministic randomization
rng(seed);

% find unique values in the specified column
uniqueVals = unique(sortedSpsWeightList(:, colIdx));

% loop through each unique value
for i = 1:length(uniqueVals)
    % find the row indices of the same value
    sameValRows = find(sortedSpsWeightList(:, colIdx) == uniqueVals(i));

    % if there are multiple rows with the same value, randomize their order
    if numel(sameValRows) > 1
        randOrder = randperm(numel(sameValRows));
        sortedSpsWeightList(sameValRows, :) = sortedSpsWeightList(sameValRows(randOrder), :);
    end
end

% restore the original RNG state
rng(oldRng);
end