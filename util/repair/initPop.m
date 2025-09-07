function [oriPop] = initPop(weight, spsWeights, deParams, lb, ub, baseline)
% INITPOP Initializes the population for Differential Evolution (DE).
%
% Inputs:
%   weight       - Current weight vector (unused in this function directly, but used by globalGauWeightInit).
%   spsWeights   - SPS matrix containing key solution vectors, used in initialization.
%   deParams     - Struct containing DE parameters, including popSize and popInitMode.
%   lb           - Lower bound for weights.
%   ub           - Upper bound for weights.
%   baseline     - Boolean flag indicating whether to include the baseline solution.
%
% Output:
%   oriPop       - Initialized population matrix (popSize × dim).

% Determine the dimension (number of weights to optimize)
dim = size(spsWeights, 1);

% === Hybrid Gaussian Initialization ===
if strcmp(deParams.popInitMode, 'hybridGuass')
    % Half population using global Gaussian init
    [globalInitPop, ~] = globalGauWeightInit(weight, spsWeights, ceil(deParams.popSize / 2), false);
    % Half population using local Gaussian perturbation around SPS
    localInitPop = localGauWeightInit(spsWeights, floor(deParams.popSize / 2), deParams.pertFactor, false);

    % Combine both and shuffle
    tempPop = [globalInitPop; localInitPop];
    shuffledIdx = randperm(size(tempPop, 1));
    oriPop = tempPop(shuffledIdx, :);

% === Fully Random Initialization ===
elseif strcmp(deParams.popInitMode, 'random')
    % Uniform sampling within bounds
    oriPop = (ub - lb) .* rand(deParams.popSize, dim) + lb;

% === Random + Hybrid Gaussian Initialization ===
elseif strcmp(deParams.popInitMode, 'randHybridGuass')
    % Divide population size into 3 parts as evenly as possible
    avgPopSize = floor(deParams.popSize / 3);
    extra = mod(deParams.popSize, 3);
    popSizeList = avgPopSize * ones(1, 3);
    popSizeList(1:extra) = popSizeList(1:extra) + 1;

    % Global Gaussian init
    [globalInitPop, ~] = globalGauWeightInit(weight, spsWeights, popSizeList(1), false);
    % Local Gaussian init
    localInitPop = localGauWeightInit(spsWeights, popSizeList(2), deParams.pertFactor, false);
    % Pure random init
    randInitPop = (ub - lb) .* rand(popSizeList(3), dim) + lb;

    % Concatenate all and shuffle
    tempPop = [globalInitPop; localInitPop; randInitPop];
    shuffledIdx = randperm(deParams.popSize);
    oriPop = tempPop(shuffledIdx, :);
end

% === Inject baseline solution (if enabled) ===
if baseline
    % Randomly replace one individual with SPS weight as a baseline
    baselineIdx = randi(deParams.popSize);
    oriPop(baselineIdx, :) = spsWeights(:, 4)';
end
end