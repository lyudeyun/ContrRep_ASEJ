function assertValidSpsWeights(spsWeights, context)
% ASSERTVALIDSPSWEIGHTS Errors out when the selected top-k carries no signal.
%
% spsWeights is [li, i, j, oriVal, spsScore]. If every score is 0, the ranking
% was a full tie and the top-k is an arbitrary set unrelated to the fault.

if nargin < 2 || isempty(context)
    context = 'current run';
end

if isempty(spsWeights) || all(spsWeights(:, 5) == 0)
    error('ContrRep:degenerateSpsWeights', ...
        ['Fault localization produced no signal for %s: every suspiciousness ' ...
        'score of the selected weights is 0.'], context);
end
end
