function [bestIndLog, fullPopLog, indFitRobMap, oriPopFitness, oriPopRobList, crPopFitness, crPopRobList, calibBestIndLog, calibFullPopLog] = initDELogs(testCaseNum, popSize, maxGen)
% INITDELOGS Initializes logging and temporary variables for DE iterations.
%
% Inputs:
%   testCaseNum - number of test cases
%   popSize     - number of individuals in the population
%   maxGen      - maximum number of generations
%
% Outputs:
%   bestIndLog      - [maxGen×1] struct log of best individuals per generation
%   fullPopLog      - [maxGen×1] struct log of full population info per generation
%   indFitRobMap    - lookup table [individual, fitness, robustness]
%   oriPopFitness   - [1×popSize] fitness of current original population
%   oriPopRobList   - [testCaseNum×popSize] robustness list of current original population
%   crPopFitness    - [1×popSize] fitness of current crossover population
%   crPopRobList    - [testCaseNum×popSize] robustness list of current crossover population
%   calibBestIndLog - same as bestIndLog, but for SR's calibration
%   calibFullPopLog - same as fullPopLog, but for SR's calibration

% Initialize log of best individual in each generation
bestIndLog(maxGen, 1) = struct( ...
    'bestInd', [], ...
    'bestFitness', [], ...
    'bestRobList', [] ...
    );

% Initialize log of full population in each generation
fullPopLog(maxGen, 1) = struct( ...
    'pop', [], ...
    'popFitness', [], ...
    'popRobList', [] ...
    );

oriPopFitness = zeros(1, popSize);
oriPopRobList = zeros(testCaseNum, popSize);

% if searchMode is 'DE'
if nargout > 5
    crPopFitness = zeros(1, popSize);
    crPopRobList = zeros(testCaseNum, popSize);
end

% if searchMode is 'DE' and 'fitnessMode' contains 'cheapincr'
if nargout > 7
    calibBestIndLog = bestIndLog;
    calibFullPopLog = fullPopLog;
end

% initialize empty lookup map for individuals and their fitness/robustness
indFitRobMap = [];
end