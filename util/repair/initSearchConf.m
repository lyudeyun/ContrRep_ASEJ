function searchConf = initSearchConf(geni, popi, fitnessMode, deFlag, altWeights, earlyCutOff, robList, prevPopFitness)
% INITSEARCHCONF Initializes the search configuration struct.
%
% Inputs:
%   geni             - Current generation index
%   popi             - Current individual index in the population
%   fitnessMode      - Fitness evaluation mode ('exp', 'cheapincr', etc.)
%   deFlag           - Identifier flag used for naming/recording
%   altWeights       - Alternative weights proposed for NN repair
%   earlyCutOff      - Whether to stop evaluation early when it becomes impossible to outperform the current best
%   robList          - Cached robustness list (may contain Inf/-Inf)
%   prevPopFitness   - Previous generation's fitness values for all individuals
%
% Output:
%   searchConf  - Struct containing the search configuration

searchConf = struct( ...
    'geni', geni, ...
    'popi', popi, ...
    'fitnessMode', fitnessMode, ...
    'deFlag', deFlag, ...
    'altWeights', altWeights, ...
    'earlyCutOff', earlyCutOff ...
    );

if nargin >= 7
    searchConf.robList = robList;
end

if nargin >= 8
    searchConf.prevPopFitness = prevPopFitness;
end
end