function [valCM, origValCM] = loadValRuns(resultsRoot, bench, benchmarkRoots)
% LOADVALRUNS Correctness measure on the 10^4 held-out inputs.
%
%   [valCM, origValCM] = loadValRuns(resultsRoot, bench, benchmarkRoots)
%
% Reads results/valEval/<bench>_DE_*_valEval.mat and <bench>_random_*_valEval.mat,
% written by ContrRep.validatePatch for the runs with the default scale
% parameter. valCM is a 1x7 cell array (expdis, expcon1, expcon3, cheapincrdis,
% cheapincrcon1, cheapincrcon3, random) holding the CM (%) of every run,
% ordered by budget; origValCM is the CM (%) of the original controller, read
% from the held-out suite, which is searched for under benchmarkRoots.
%
% As on the test inputs used during the search, a run whose delivered
% controller does not improve on the original one (fitness <= 0) keeps the
% original controller.

modes = {'expdis', 'expcon1', 'expcon3', 'cheapincrdis', 'cheapincrcon1', 'cheapincrcon3'};
de = dir(fullfile(resultsRoot, 'valEval', [bench '_DE_*_valEval.mat']));
rd = dir(fullfile(resultsRoot, 'valEval', [bench '_random_*_valEval.mat']));
if numel(de) ~= 1 || numel(rd) ~= 1
    error('loadValRuns:files', 'Expected one DE and one random valEval file for %s', bench);
end
d = load(fullfile(de.folder, de.name));
r = load(fullfile(rd.folder, rd.name));

valTS = [];
for k = 1:numel(benchmarkRoots)
    f = dir(fullfile(benchmarkRoots{k}, '**', d.meta.valTSFile));
    if ~isempty(f)
        valTS = load(fullfile(f(1).folder, f(1).name), 'testSuite').testSuite;
        break;
    end
end
if isempty(valTS)
    error('loadValRuns:suite', 'Held-out suite %s not found', d.meta.valTSFile);
end
origValCM = 100 * valTS.sn / valTS.size;

valCM = cell(1, 7);
budgets = cell(1, 7);
entries = [d.valEval(:); r.valEval(:)];
for k = 1:numel(entries)
    e = entries(k);
    if ~contains(e.srcFile, '_scaleParam_2_')
        error('loadValRuns:scale', 'Unexpected scale parameter in %s', e.srcFile);
    end
    if contains(e.srcFile, 'searchmode_random')
        ai = 7;
    else
        fm = regexp(e.srcFile, 'fitmode_(\w+?)_budget', 'tokens', 'once');
        ai = find(strcmp(modes, fm{1}));
    end
    if e.fitness <= 0
        v = origValCM;
    else
        v = 100 * sum(e.valRob > 0) / numel(e.valRob);
    end
    valCM{ai}(end+1) = v;
    budgets{ai}(end+1) = str2double(regexp(e.srcFile, 'budget_(\d+)', 'tokens', 'once'));
end
for ai = 1:7
    [~, order] = sort(budgets{ai});
    valCM{ai} = valCM{ai}(order);
end
end
