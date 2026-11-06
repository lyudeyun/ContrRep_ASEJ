% === Section 6.4 (search algorithm settings): effect of the weight lambda = 10^4 ===
% The fitness of the continuous fitness functions is F = lambda * D + C, where
% D is the number of test inputs repaired minus those broken (an integer) and
% C the summed change in robustness. lambda = 10^4 is meant to let D decide:
% an individual passing more test inputs should have a higher F. This fails
% when the C of two individuals differs by more than lambda.
%
% For the runs with the default scale parameter (budget 1..10) of the four
% continuous versions (Exp-all, Exp-neg, Fast-all, Fast-neg), this script counts
%   replacements - DE selection steps in which the trial individual replaced
%                  its parent (the population of fullPopLog changed)
%   inversions   - replacements in which the new individual passes fewer test
%                  inputs than the one it replaced, i.e., the order given by F
%                  differs from the order given by D
% and checks whether this affected the delivered controller:
%   Exp  - does the delivered controller, bestIndLog(g), pass as many test
%          inputs as the best individual of all the logged populations?
%   Fast - does the delivered controller, calibBestIndLog(g), pass as many
%          test inputs as the best individual of the calibrated last
%          generation, calibFullPopLog(g)? Calibration rescores with the
%          number of passing test inputs only (expdis) the individuals that
%          skipped some test inputs; an individual that skipped none keeps its
%          search fitness lambda * D + C. The script also counts these
%          individuals in the last generation: if there are none, the
%          delivered controller does not depend on lambda.
% D is computed as the search saw it: for Fast during the search, the skipped
% test inputs count as recorded (+Inf passing, -Inf failing); for Exp, test
% inputs left unevaluated by the early cut-off (NaN) count as failing, and the
% inversions involving such individuals are reported separately.
%
% Can be run from any folder: the repository root is found from the location
% of this script (private/repoRoot.m).
clear; clc;
warning('off', 'all');   % result files hold Breach objects that cannot be reconstructed here
root = repoRoot();
addpath(genpath(fullfile(root, 'util')));

resultsRoot = fullfile(root, 'results');
scaleParam  = '2';
nRuns       = 10;
modes       = {'expcon1', 'expcon3', 'cheapincrcon1', 'cheapincrcon3'};

caseTable = benchmarkCases();
nB = size(caseTable, 1);
nM = numel(modes);
nRep = zeros(nB, nM); nInv = zeros(nB, nM); nInvNaN = zeros(nB, nM);
nNotBest = zeros(nB, nM); nRunsDone = zeros(nB, nM); nKeptFit = zeros(nB, nM);

for b = 1:nB
    folder = fullfile(resultsRoot, caseTable{b, 2}, 'DE', caseTable{b, 3});
    d = dir(fullfile(folder, '*.mat'));
    files = {d.name};
    for m = 1:nM
        sel = files(contains(files, ['_scaleParam_' scaleParam '_']) ...
            & contains(files, ['_fitmode_' modes{m} '_budget_']));
        budgets = cellfun(@(f) str2double(regexp(f, 'budget_(\d+)', 'tokens', 'once')), sel);
        sel = sel(budgets >= 1 & budgets <= nRuns);
        if numel(sel) ~= nRuns
            error('Expected %d runs for %s %s, found %d', nRuns, caseTable{b, 2}, modes{m}, numel(sel));
        end
        for k = 1:numel(sel)
            c = load(fullfile(folder, sel{k}));
            sortedTS = sortTestSuite(c.mutant.mut_TS);
            origSR = sum([sortedTS.testCases.rob] > 0);
            G = find(~cellfun(@isempty, {c.fullPopLog.pop}), 1, 'last');
            passed = @(P) sum(P > 0, 1) - origSR;    % D of every individual (column)

            maxD = -Inf;
            for g = 1:G
                P = c.fullPopLog(g).popRobList;
                D = passed(P);
                maxD = max(maxD, max(D));
                if g == 1, continue; end
                Pprev = c.fullPopLog(g - 1).popRobList;
                Dprev = passed(Pprev);
                replaced = any(c.fullPopLog(g - 1).pop ~= c.fullPopLog(g).pop, 2)';
                inv = replaced & D < Dprev;
                nRep(b, m) = nRep(b, m) + nnz(replaced);
                nInv(b, m) = nInv(b, m) + nnz(inv);
                nInvNaN(b, m) = nInvNaN(b, m) + nnz(inv & (any(isnan(P), 1) | any(isnan(Pprev), 1)));
            end

            if startsWith(modes{m}, 'cheapincr')
                delivered = sum(c.calibBestIndLog(G).bestRobList > 0) - origSR;
                best = max(passed(c.calibFullPopLog(G).popRobList));
                nKeptFit(b, m) = nKeptFit(b, m) + nnz(~any(isinf(c.fullPopLog(G).popRobList), 1));
            else
                delivered = sum(c.bestIndLog(G).bestRobList > 0) - origSR;
                best = maxD;
            end
            nNotBest(b, m) = nNotBest(b, m) + (delivered < best);
            nRunsDone(b, m) = nRunsDone(b, m) + 1;
        end
    end
    fprintf('%s done\n', caseTable{b, 2});
end

names = {'Exp-all', 'Exp-neg', 'Fast-all', 'Fast-neg'};
fprintf('\nreplacements / inversions (of which with NaN) / runs whose delivered controller is not the best, per benchmark\n');
fprintf('%-10s', 'benchmark'); fprintf(' %24s', names{:}); fprintf('\n');
for b = 1:nB
    fprintf('%-10s', caseTable{b, 2});
    for m = 1:nM
        fprintf(' %24s', sprintf('%d / %d (%d) / %d', nRep(b, m), nInv(b, m), nInvNaN(b, m), nNotBest(b, m)));
    end
    fprintf('\n');
end

groups = {'Exp (Exp-all, Exp-neg)', [1 2]; 'Fast (Fast-all, Fast-neg)', [3 4]; 'all four', 1:4};
fprintf('\n');
for gi = 1:size(groups, 1)
    cols = groups{gi, 2};
    r = sum(nRep(:, cols), 'all'); v = sum(nInv(:, cols), 'all');
    fprintf('%-26s runs %4d  replacements %6d  inversions %4d (%.3f%%, %d involving NaN)  delivered controller not the best: %d runs\n', ...
        groups{gi, 1}, sum(nRunsDone(:, cols), 'all'), r, v, 100 * v / r, ...
        sum(nInvNaN(:, cols), 'all'), sum(nNotBest(:, cols), 'all'));
end
fprintf(['Fast: individuals of the calibrated last generation that kept their search fitness ' ...
    '(no skipped test input): %d\n'], sum(nKeptFit(:, 3:4), 'all'));
