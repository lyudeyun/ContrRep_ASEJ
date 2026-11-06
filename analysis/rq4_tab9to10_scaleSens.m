% === RQ4, Tables 9-10: sensitivity of ContrRep and Random to the scale parameter ===
% Prints the LaTeX rows of
%   Table 9 (tab:avgCMScale)         - difference between the average CM (10
%                                      runs) with s = 1.5 or s = 3 and the one
%                                      with the default s = 2
%   Table 10 (tab:avgExecTestsScale) - same for the number of executed tests,
%                                      as a percentage of the test-execution
%                                      budget of DE (popSize * maxGen * #test inputs)
% The delivered controller and the executed tests of a run are as in
% rq123_tab4to7_cmExec.m (private/loadRepairRuns.m).
%
% Cells are shaded in green (improve) or red (degrade) with intensity
% min(35, round(8 * sqrt(|difference|))); a difference that rounds to 0.0 is
% not shaded. For CM a positive difference is an improvement, for executed
% tests a negative one.
%
% Can be run from any folder: the repository root is found from the location
% of this script (private/repoRoot.m).
clear; clc;
warning('off', 'all');   % result files hold Breach objects that cannot be reconstructed here
root = repoRoot();
addpath(genpath(fullfile(root, 'util')));

resultsRoot = fullfile(root, 'results');
scales      = {'1.5', '3'};
refScale    = '2';
nRuns       = 10;

caseTable = benchmarkCases();

nB = size(caseTable, 1);
allScales = [{refScale}, scales];
cmMean = nan(nB, 7, numel(allScales));
exPct  = nan(nB, 7, numel(allScales));

for b = 1:nB
    for s = 1:numel(allScales)
        fprintf('loading %s, s = %s\n', caseTable{b, 2}, allScales{s});
        R = loadRepairRuns(resultsRoot, caseTable{b, 2}, caseTable{b, 3}, caseTable{b, 4}, allScales{s}, nRuns);
        nTests = numel(R(1).origRob);
        for a = 1:7
            cmMean(b, a, s) = mean(100 * R(a).newSR / nTests);
            exPct(b, a, s)  = 100 * mean(R(a).execTests) / R(1).fullBudget;
        end
    end
end

fprintf('\n%% ===== tab:avgCMScale =====\n');
printDeltaRows(caseTable(:, 1), cmMean, scales, true);
fprintf('\n%% ===== tab:avgExecTestsScale =====\n');
printDeltaRows(caseTable(:, 1), exPct, scales, false);


function printDeltaRows(labels, X, scales, higherIsBetter)
% X(b, a, 1) is the reference scale, X(b, a, 1 + k) the k-th compared scale
for b = 1:numel(labels)
    for k = 1:numel(scales)
        delta = X(b, :, 1 + k) - X(b, :, 1);
        cells = arrayfun(@(d) deltaCell(d, higherIsBetter), delta, 'UniformOutput', false);
        if k == 1
            head = sprintf('\\multirow{%d}{*}{%s}', numel(scales), labels{b});
        else
            head = '';
        end
        fprintf('%s & %s & %s \\\\\n', head, scales{k}, strjoin(cells, ' & '));
    end
    if b < numel(labels)
        fprintf('\\cmidrule(lr){1-9}\n');
    end
end
end


function c = deltaCell(d, higherIsBetter)
r = str2double(fmtFixed(d, 1));
if r == 0
    c = '\phantom{$+$}0.0';
    return;
end
if r > 0, sign_ = '$+$'; else, sign_ = '$-$'; end
if (r > 0) == higherIsBetter, color = 'improve'; else, color = 'degrade'; end
intensity = min(35, round(8 * sqrt(abs(r))));
c = sprintf('\\cellcolor{%s!%d}%s%.1f', color, intensity, sign_, abs(r));
end
