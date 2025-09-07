function [bestIndLog, fullPopLog, bestInd, bestFitness, bestRobList] = updateRandomLogs(bestIndLog, fullPopLog, ...
    bestInd, bestFitness, bestRobList, ...
    curPop, curPopFitness, curPopRobList, ...
    geni)
% UPDATERANDOMLOGS Updates random state and logs for one generation by performing survivor selection
% between the current and trial populations. It updates the population, global best individual,
% and logging information for the current generation.
%
% Inputs
%   bestIndLog: array logging best individual per generation
%   fullPopLog: array logging full population per generation
%   bestInd: current global best individual
%   bestFitness: current global best fitness
%   bestRobList: current global best robustness list
%   curPop: current population [popSize × dim]
%   curPopFitness: fitness values of curPop [1 × popSize]
%   curPopRoblist: robustness lists of curPop [testCaseNum × popSize]
%   geni: current generation index
%
% Outputs
%   bestIndLog, fullPopLog: updated generation logs
%   bestInd, bestFitness, bestRobList: updated global best


% find best individual in each generation
[curPopBestInd, curPopBestFitness, curPopBestRobList]  = findBestIndividual(curPop, curPopFitness, curPopRobList);

% geni is greater than 1
if ~isempty(bestInd)
    if curPopBestFitness > bestFitness
        % update bestInd, bestFitness, bestRobList
        bestInd = curPopBestInd;
        bestFitness = curPopBestFitness;
        bestRobList = curPopBestRobList;
    end
else
    bestInd = curPopBestInd;
    bestFitness = curPopBestFitness;
    bestRobList = curPopBestRobList;
end

% record the best individual and its fitness value
bestIndLog(geni).bestInd = bestInd;
bestIndLog(geni).bestFitness = bestFitness;
bestIndLog(geni).bestRobList = bestRobList;

% display the best fitness value of the current generation
fprintf('%d      %f\n', geni, bestFitness);

% record the X, fitnessX and roblistX of current generation
fullPopLog(geni).pop = curPop;
fullPopLog(geni).popFitness = curPopFitness;
fullPopLog(geni).popRobList = curPopRobList;