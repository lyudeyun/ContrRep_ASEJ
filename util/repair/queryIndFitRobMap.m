function [curFitness, curRobList, isFound] = queryIndFitRobMap(indFitRobMap, altWeights)
% QUERYINDFITROPMAP Queries fitness and robustness for a given individual.
%
% Inputs
%   indFitRobMap: lookup table [individual, fitness, robustness]
%   altWeights: individual (1 × dim) whose fitness/robustness to query
%
% Outputs
%   curFitness: fitness value if found; empty otherwise
%   curRobList: robustness list if found; empty otherwise
%   isFound: true if a unique match is found, false otherwise

dim = numel(altWeights);
logicIdx = ismember(indFitRobMap(:, 1:dim), altWeights, 'rows');
foundIdx = find(logicIdx);

if isempty(foundIdx)
    % no match found
    curFitness = [];
    curRobList = [];
    isFound = false;
elseif isscalar(foundIdx)
    % unique match
    curFitness = indFitRobMap(foundIdx, dim + 1);
    curRobList = indFitRobMap(foundIdx, dim + 2:end)';
    isFound = true;
else
    % multiple matches found (data inconsistency)
    error('queryIndFitRobMap:DuplicateMatch', 'Duplicate individual found. Check deduplication.');
end
end