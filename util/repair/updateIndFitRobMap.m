function indFitRobMap = updateIndFitRobMap(indFitRobMap, pop, popFitness, popRobList)
% UPDATEINDFITROBMAP Updates and deduplicates the individual-fitness-robustness map.
%
% Inputs
%   indFitRobMap: current lookup table [pop, fitness, robustness]
%   pop: current population [popSize × dim]
%   popFitness: fitness values [1 × popSize]
%   popRobList: robustness values [testCaseNum × popSize]
%
% Output
%   indFitRobMap: updated and deduplicated lookup table

% generate the individual-fitness-robustness map for the current generation
curIndFitRobMap = [pop, popFitness', popRobList'];

% merge and deduplicate (keep first occurrence)
indFitRobMap = [indFitRobMap; curIndFitRobMap];
dim = size(pop, 2);
[~, idx] = unique(indFitRobMap(:, 1:dim), 'rows', 'stable');
indFitRobMap = indFitRobMap(idx, :);
end