function [bestInd, bestFitness, bestRobList] = findBestIndividual(pop, popFitness, popRobList)
% FINDBESTINDIVIDUAL Returns the best individual, its fitness and its robustness list from a population.
%
% Inputs:
%   pop: [popSize × dim] population matrix
%   popFitness: [1 × popSize] fitness values
%   popRobList: [testCaseNum × popSize] robustness values
%
% Outputs:
%   bestInd: best individual
%   bestFitness: its fitness value
%   bestRobList: its robustness list

[bestFitness, bestIdx] = max(popFitness);
bestInd = pop(bestIdx, :);
bestRobList = popRobList(:, bestIdx);
end