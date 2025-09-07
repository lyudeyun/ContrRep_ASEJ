function [calibBestIndLog, calibFullPopLog, indFitRobMap] = updateCalibDELogs(calibBestIndLog, calibFullPopLog, indFitRobMap, ...
    curPop, curCalibPopFitness, curCalibPopRobList, geni)
% UPDATECALIBDELOGS Updates DE state and logs for one generation by performing survivor selection
% between the current and trial populations. It updates the population, global best individual,
% and logging information for the current generation.
%
% Inputs
%   calibBestIndLog: array logging best individual per generation
%   calibFullPopLog: array logging full population per generation
%   indFitRobMap: current lookup table
%   curPop: current population [popSize × dim]
%   curCalibPopFitness: fitness values of oriPop [1 × popSize]
%   curCalibPopRobList: robustness lists of oriPop [testCaseNum × popSize]
%   geni: current generation index
%
% Outputs
%   calibBestIndLog, calibFullPopLog: updated generation logs
%   indFitRobMap: updated lookup table

% update lookup table with crossover population results
indFitRobMap = updateIndFitRobMap(indFitRobMap, curPop, curCalibPopFitness, curCalibPopRobList);

% find best individual in current generation
[curCalibBestInd, curCalibBestFitness, curCalibBestRobList] = findBestIndividual(curPop, curCalibPopFitness, curCalibPopRobList);

% record the best individual and its fitness value
calibBestIndLog(geni).bestInd = curCalibBestInd;
calibBestIndLog(geni).bestFitness = curCalibBestFitness;
calibBestIndLog(geni).bestRobList = curCalibBestRobList;

% record the X, fitnessX and roblistX of current generation
calibFullPopLog(geni).pop = curPop;
calibFullPopLog(geni).popFitness = curCalibPopFitness;
calibFullPopLog(geni).popRobList = curCalibPopRobList;

% display the best fitness value of the current generation
fprintf('%d      %f\n', geni, curCalibBestFitness);
end