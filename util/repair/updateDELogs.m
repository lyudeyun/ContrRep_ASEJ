function [bestIndLog, fullPopLog, indFitRobMap, oriPop, oriPopFitness, oriPopRobList] = updateDELogs(bestIndLog, fullPopLog, indFitRobMap, ...
    bestInd, bestFitness, bestRobList, ...
    oriPop, oriPopFitness, oriPopRobList, ...
    crPop, crPopFitness, crPopRobList, geni)
% UPDATEDELOGS Updates DE state and logs for one generation by performing survivor selection
% between the current and trial populations. It updates the population, global best individual,
% and logging information for the current generation.
%
% Inputs
%   bestIndLog: array logging best individual per generation
%   fullPopLog: array logging full population per generation
%   indFitRobMap: current lookup table
%   bestInd: current global best individual
%   bestFitness: current global best fitness
%   bestRobList: current global best robustness list
%   oriPop: current population [popSize × dim]
%   oriPopFitness: fitness values of oriPop [1 × popSize]
%   oriPopRoblist: robustness lists of oriPop [testCaseNum × popSize]
%   crPop: crossover (trial) population [popSize × dim]
%   crPopFitness: fitness values of crPop [1 × popSize]
%   crPopRobList: robustness lists of crPop [testCaseNum × popSize]
%   geni: current generation index
%
% Outputs
%   bestIndLog, fullPopLog: updated generation logs
%   indFitRobMap: updated lookup table
%   oriPop, oriPopFitness, oriPopRobList: updated population
%   bestInd, bestFitness, bestRobList: updated global best

[popSize, ~] = size(oriPop);

% update lookup table with crossover population results
indFitRobMap = updateIndFitRobMap(indFitRobMap, crPop, crPopFitness, crPopRobList);

% select next generation
for popi = 1:popSize
    % replace parent with better offspring
    if crPopFitness(popi) > oriPopFitness(popi)
        oriPop(popi, :) = crPop(popi, :);
        oriPopFitness(popi) = crPopFitness(popi);
        oriPopRobList(:, popi) = crPopRobList(:, popi);
    end
    %  update global best if necessary
    if oriPopFitness(popi) > bestFitness
        bestInd = oriPop(popi, :);
        bestFitness = oriPopFitness(popi);
        bestRobList = oriPopRobList(:, popi);
    end
end

% record the best individual and its fitness value
bestIndLog(geni).bestInd = bestInd;
bestIndLog(geni).bestFitness = bestFitness;
bestIndLog(geni).bestRobList = bestRobList;

% record population, fitness and robustness of current generation
fullPopLog(geni).pop = oriPop;
fullPopLog(geni).popFitness = oriPopFitness;
fullPopLog(geni).popRobList = oriPopRobList;

% display the best fitness value of the current generation
fprintf('%d      %f\n', geni, bestFitness);
end