function pop = localGauWeightInit(spsWeights, popSize, pertFactor, baseline)
% LOCALGAUWEIGHTINIT generates a population by applying local Gaussian perturbations to suspicious weights.
%
% Inputs:
%   spsWeights: [li, i, j, oriVal, spsScore]
%   popSize: number of individuals in the population
%   pertFactor: perturbation factor in [0,1]
%   baseline:
% Outputs:
%   pop: initialized population; each row is an individual

spsWNum = size(spsWeights,1);
spsWeightValues = spsWeights(:,4)';

% Initialize population with the repeated suspicious weights
pop = repmat(spsWeightValues, popSize, 1);


% The first row is kept as the original weights to ensure that the population
% includes the baseline solution, which helps prevent the loss of a known-good reference.
if baseline
    startIdx = 2;
else
    startIdx = 1;
end

for i = startIdx:popSize
    sigma =  pertFactor * spsWeightValues;
    pop(i,:) = pop(i,:) + sigma .* randn(1,spsWNum);
end
end
