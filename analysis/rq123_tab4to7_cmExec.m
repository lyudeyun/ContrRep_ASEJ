% === RQ1-RQ3, Tables 4-7: correctness and cost of the repair approaches ===
% Prints the LaTeX rows of
%   Table 4 (tab:avgCM)              - CM of the original and the repaired
%                                      controllers, on the 100 test inputs used
%                                      during the search and on the 10^4
%                                      held-out inputs (mean and std, 10 runs)
%   Table 5 (tab:statTestsCM)        - paired Cohen's d between approaches on CM
%   Table 6 (tab:avgExecTests)       - number of executed tests (in 10^4)
%   Table 7 (tab:statTestsExecTests) - paired Cohen's d on executed tests
% for the six versions of ContrRep, Random, and ISAR, with the default scale
% parameter.
%
% See private/loadRepairRuns.m for which controller is delivered by a run
% and how executed tests are counted. ISAR is read from the results/contrrep/
% folder of the ISAR repository (isarRoot below); if it is not there, the ISAR
% column is left empty and the effect sizes are computed without ISAR.
%
% Effect sizes (paired Cohen's d across the 10 benchmarks, on per-benchmark means):
%   CM             - improvement over the original controller, divided by the
%                    largest average improvement among the compared approaches
%                    on that benchmark
%   executed tests - divided by the test-execution budget of DE on that
%                    benchmark (popSize * maxGen * #test inputs); lower is better
%   |d| < 0.2 negligible, < 0.5 small, < 0.8 medium, otherwise large.
%
% Can be run from any folder: the repository root is found from the location
% of this script (private/repoRoot.m).
clear; clc;
warning('off', 'all');   % result files hold Breach objects that cannot be reconstructed here
root = repoRoot();
addpath(genpath(fullfile(root, 'util')));

resultsRoot    = fullfile(root, 'results');
benchmarkRoots = {fullfile(root, 'FLRepBenchGen'), fullfile(root, 'benchmark')};   % where the held-out suites are
isarRoot       = fullfile(root, '..', 'ISAR', 'results', 'contrrep');
scaleParam     = '2';
nRuns          = 10;

caseTable = benchmarkCases();
apprNames = {'Exp-disc', 'Exp-all', 'Exp-neg', 'Fast-disc', 'Fast-all', 'Fast-neg', 'Random', 'ISAR'};

hasIsar = isfolder(isarRoot);
if ~hasIsar
    fprintf(2, 'ISAR results not found in %s; the ISAR column is left empty.\n', isarRoot);
end

nB = size(caseTable, 1);
nA = numel(apprNames);
cm = cell(nB, nA); valCM = cell(nB, nA); ex = cell(nB, nA);
origCM = nan(nB, 1); origValCM = nan(nB, 1); fullBudget = nan(nB, 1);

for b = 1:nB
    fprintf('loading %s\n', caseTable{b, 2});
    R = loadRepairRuns(resultsRoot, caseTable{b, 2}, caseTable{b, 3}, caseTable{b, 4}, scaleParam, nRuns);
    nTests = numel(R(1).origRob);
    origCM(b) = 100 * R(1).origSR / nTests;
    fullBudget(b) = R(1).fullBudget;
    for a = 1:7
        cm{b, a} = 100 * R(a).newSR / nTests;
        ex{b, a} = R(a).execTests;
    end
    [v, origValCM(b)] = loadValRuns(resultsRoot, caseTable{b, 2}, benchmarkRoots);
    valCM(b, 1:7) = v;

    if hasIsar
        I = loadIsarRuns(isarRoot, caseTable{b, 5}, nRuns);
        cm{b, 8} = 100 * I.newSR / numel(I.origRob);
        ex{b, 8} = I.execTests;
        valCM{b, 8} = I.valCM;
    else
        [cm{b, 8}, ex{b, 8}, valCM{b, 8}] = deal(nan);
    end
end

avg = @(c) cellfun(@mean, c);
sd  = @(c) cellfun(@std, c);
cmMean = avg(cm);     cmStd = sd(cm);
valMean = avg(valCM); valStd = sd(valCM);
exMean = avg(ex) / 1e4; exStd = sd(ex) / 1e4;

% ---------- effect sizes ----------
cols = find(all(~isnan(cmMean), 1));          % approaches with results
gain = cmMean(:, cols) - origCM;
normCM = gain ./ max(gain, [], 2);
execRatio = exMean(:, cols) * 1e4 ./ fullBudget;
dCM = pairedD(normCM);
dEx = pairedD(execRatio);

% ---------- LaTeX ----------
fprintf('\n%% ===== tab:avgCM =====\n');
fprintf('%% Test inputs used during the search\n');
for b = 1:nB
    fprintf('%s & %d & %s \\\\\n', caseTable{b, 1}, round(origCM(b)), ...
        meanStdCells(cmMean(b, :), cmStd(b, :), 1, true));
end
fprintf('%% Held-out inputs\n');
for b = 1:nB
    fprintf('%s & %.1f & %s \\\\\n', caseTable{b, 1}, origValCM(b), ...
        meanStdCells(valMean(b, :), valStd(b, :), 1, true));
end

fprintf('\n%% ===== tab:statTestsCM (row vs column) =====\n');
printEffectRows(dCM, apprNames(cols), false);

fprintf('\n%% ===== tab:avgExecTests (10^4) =====\n');
for b = 1:nB
    fprintf('%s & %s \\\\\n', caseTable{b, 1}, meanStdCells(exMean(b, :), exStd(b, :), 2, false));
end

fprintf('\n%% ===== tab:statTestsExecTests (row vs column) =====\n');
printEffectRows(dEx, apprNames(cols), true);


function D = pairedD(X)
% paired Cohen's d between every pair of columns of X (rows are benchmarks)
n = size(X, 2);
D = nan(n);
for i = 1:n
    for j = 1:n
        D(i, j) = computeCohens_d(X(:, i), X(:, j), 'paired');
    end
end
end


function printEffectRows(D, names, lowerIsBetter)
% one row per approach; a positive d means that the row approach has the
% higher value, which is better for CM and worse for executed tests
if lowerIsBetter, D = -D; end
n = size(D, 1);
for i = 1:n
    cells = cell(1, n);
    for j = 1:n
        if i == j
            cells{j} = '\same';
        else
            cells{j} = effectMacro(D(i, j));
        end
    end
    fprintf('%% %s\n& %s \\\\\n', names{i}, strjoin(cells, ' & '));
end
end


function m = effectMacro(d)
if abs(d) < 0.2
    m = '\cohensdNegligible';
    return;
end
if abs(d) < 0.5, size_ = 'Small'; elseif abs(d) < 0.8, size_ = 'Medium'; else, size_ = 'Large'; end
if d > 0, dir_ = 'Better'; else, dir_ = 'Worse'; end
m = ['\cohensd' size_ dir_];
end
