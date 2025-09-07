function [pop, layerGauInfo] = globalGauWeightInit(weight, spsWeights, popSize, baseline)
% GLOBALGAUWEIGHTINIT Initializes population using layer-wise Gaussian distributions.
% Each individual is sampled from a Gaussian distribution fitted
% on its corresponding layer's weights.
%
% Inputs
%   weight: cell array of weights per layer
%   spsWeights: suspicious weights in format [li, i, j, oriVal, spsScore]
%   popSize: number of individuals in the population
%   baseline: true/false
%
% Outputs
%   pop: [popSize × spsWNum] initialized population matrix
%   layerGauInfo: [layerNum × 2] matrix of (mean, std) per layer

[spsWNum, ~] = size(spsWeights);
pop = zeros(popSize, spsWNum);

allLNum = numel(weight);
layerGauInfo = zeros(allLNum, 2);

% compute layer-wise mean and std to build Gaussian distributions
for li = 1:allLNum
    curLayerWeights = weight{li};
    % mean
    layerGauInfo(li,1) = mean(curLayerWeights, 'all');
    % std
    layerGauInfo(li,2) = std(curLayerWeights(:));
end

% sample each column from corresponding layer's Gaussian distribution
for wi = 1:spsWNum
    li = spsWeights(wi, 1);
    sampledWeights = normrnd(layerGauInfo(li, 1), layerGauInfo(li, 2), [popSize, 1]);
    pop(:, wi) = sampledWeights;
end

% replace the first individual with the original weights to ensure baseline performance
if baseline
    pop(1, :) = spsWeights(:,4)';
end