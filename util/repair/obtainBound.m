function [lb, ub] = obtainBound(spsWeights)
% OBTAINBOUND determines the lower bound and the upper bound of the suspicious weights at the same layer.
%
% Inputs:
%   spsWeights: [li, i, j, oriVal, spsScore]
%
% Outputs
%   lb: lower bound
%   ub: upper bound

spsWNum = size(spsWeights, 1);
layerIdxs = spsWeights(:,1);
weightVals = spsWeights(:,4);

% identify unique layers and assign a group index to each row
[groupIdxs, layers] = findgroups(layerIdxs);

% group-wise aggregation: compute the minimum and maximum weight for each layer
minWeight = splitapply(@min, weightVals, groupIdxs);
maxWeight = splitapply(@max, weightVals, groupIdxs);

lb = zeros(1,spsWNum);
ub = zeros(1,spsWNum);

for wi = 1: spsWNum

    idx = groupIdxs(wi);

    minW = minWeight(idx, 1);
    maxW = maxWeight(idx, 1);

    if minW < 0
        lb(1,wi) = 2 * minW;
    else
        lb(1,wi) = minW/2;
    end
    if maxW > 0
        ub(1,wi) = 2 * maxW;
    else
        ub(1,wi) = maxW/2;
    end
end
end