% === RQ5, Table 12: repaired and preserved test inputs ===
% Prints the LaTeX rows of
%   Table 12a (tab:rq4_repaired)  - Rep.:  % of the originally failing test
%                                   inputs that pass after the repair
%   Table 12b (tab:rq4_preserved) - Pres.: % of the originally passing test
%                                   inputs that still pass
% (mean and std over 10 runs) for the six versions of ContrRep, Random, and
% ISAR, with the default scale parameter.
%
% See private/loadRepairRuns.m for which controller is delivered by a
% run. ISAR is read from the results/contrrep/ folder of the ISAR repository
% (isarRoot below); if it is not there, the ISAR column is left empty.
%
% Can be run from any folder: the repository root is found from the location
% of this script (private/repoRoot.m).
clear; clc;
warning('off', 'all');   % result files hold Breach objects that cannot be reconstructed here
root = repoRoot();
addpath(genpath(fullfile(root, 'util')));

resultsRoot = fullfile(root, 'results');
isarRoot    = fullfile(root, '..', 'ISAR', 'results', 'contrrep');
scaleParam  = '2';
nRuns       = 10;

caseTable = benchmarkCases();
nB = size(caseTable, 1);
nA = 8;   % six versions of ContrRep, Random, ISAR

hasIsar = isfolder(isarRoot);
if ~hasIsar
    fprintf(2, 'ISAR results not found in %s; the ISAR column is left empty.\n', isarRoot);
end

rep = cell(nB, nA); pres = cell(nB, nA);
for b = 1:nB
    fprintf('loading %s\n', caseTable{b, 2});
    R = loadRepairRuns(resultsRoot, caseTable{b, 2}, caseTable{b, 3}, caseTable{b, 4}, scaleParam, nRuns);
    for a = 1:7
        [rep{b, a}, pres{b, a}] = repPres(R(a).origRob, R(a).finalRob);
    end
    if hasIsar
        I = loadIsarRuns(isarRoot, caseTable{b, 5}, nRuns);
        [rep{b, 8}, pres{b, 8}] = repPres(I.origRob, I.finalRob);
    else
        [rep{b, 8}, pres{b, 8}] = deal(nan);
    end
end

avg = @(c) cellfun(@mean, c);
sd  = @(c) cellfun(@std, c);

fprintf('\n%% ===== tab:rq4_repaired =====\n');
for b = 1:nB
    fprintf('%s & %s \\\\\n', caseTable{b, 1}, meanStdCells(avg(rep(b, :)), sd(rep(b, :)), 1, true));
end
fprintf('\n%% ===== tab:rq4_preserved =====\n');
for b = 1:nB
    fprintf('%s & %s \\\\\n', caseTable{b, 1}, meanStdCells(avg(pres(b, :)), sd(pres(b, :)), 1, true));
end


function [r, p] = repPres(origRob, finalRob)
% per run: % of the originally failing tests that pass, and of the originally
% passing tests that still pass
r = 100 * sum((origRob < 0) & (finalRob > 0), 1) / sum(origRob < 0);
p = 100 * sum((origRob > 0) & (finalRob > 0), 1) / sum(origRob > 0);
end
