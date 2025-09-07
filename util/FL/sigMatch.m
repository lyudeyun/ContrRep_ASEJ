function  sigVals = sigMatch(Br, sigNames)
% SIGMATCH Extracts the trajectories of specific signals from a BreachSimulinkSystem.
%
% Inputs
%   Br: a BreachSimulinkSystem instance
%   sigNames: cell array of signal names to extract
%
% Outputs
%   sigVals: matrix where each row is the trajectory of a specified signal

allSigNames = Br.GetSignalList();
allSigVals = Br.P.traj{1,1}.X;

sigVals = [];
for i = 1:numel(sigNames)
    idx = find(strcmp(sigNames{i}, allSigNames), 1);
    if isempty(idx)
        error('Signal "%s" not found.', sigNames{i});
    end
    sigVals(end+1, :) = allSigVals(idx, :);
end
end