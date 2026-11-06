function R = loadRepairRuns(resultsRoot, bench, deSub, rndSub, scaleParam, maxRuns)
% LOADREPAIRRUNS Outcome of the ContrRep and Random runs of one benchmark.
%
%   R = loadRepairRuns(resultsRoot, bench, deSub, rndSub, scaleParam, maxRuns)
%
% Reads results/<bench>/DE/<deSub>/ and results/<bench>/random/<rndSub>/ and
% keeps, for each of the seven approaches, the runs with the given scale
% parameter (budget 1..maxRuns, in this order). R is a 1x7 struct array in the
% order expdis, expcon1, expcon3, cheapincrdis, cheapincrcon1, cheapincrcon3,
% random, with fields
%   name       - fitness mode ('random' for the Random baseline)
%   budgets    - budget (run index) of every run
%   files      - result file of every run
%   newSR      - number of passing test inputs of the delivered controller
%   finalRob   - robustness of every test input under the delivered controller
%                (one column per run, test inputs sorted as in sortTestSuite)
%   execTests  - number of executed tests of every run
%   origRob    - robustness of every test input under the original controller
%   origSR     - number of passing test inputs of the original controller
%   fullBudget - test-execution budget of DE: popSize * maxGen * #test inputs
%
% Delivered controller: the best individual of the last generation that was
% run, bestIndLog(g), or calibBestIndLog(g) for the approximate fitness
% (cheapincr*). If it does not pass more test inputs than the original
% controller, the original controller is kept.
%
% Executed tests: cheapincr* skips test inputs by design, so its executions
% are counted as they happened (finite entries of fullPopLog for every
% generation but the last, plus the whole last generation, whose skipped
% inputs are executed to select the returned individual). The other modes
% only skip test inputs through an early cut-off that any search could adopt,
% so they are charged the whole suite for every individual of every generation.

modes = {'expdis', 'expcon1', 'expcon3', 'cheapincrdis', 'cheapincrcon1', 'cheapincrcon3', 'expdis'};
searchModes = [repmat({'DE'}, 1, 6), {'random'}];
names = [modes(1:6), {'random'}];

R = struct('name', names, 'budgets', [], 'files', {{}}, 'newSR', [], ...
    'finalRob', [], 'execTests', [], 'origRob', [], 'origSR', [], 'fullBudget', []);

for ai = 1:7
    sub = deSub;
    if strcmp(searchModes{ai}, 'random'), sub = rndSub; end
    folder = fullfile(resultsRoot, bench, searchModes{ai}, sub);
    files = dir(fullfile(folder, '*.mat'));
    names_ = {files.name};
    names_ = names_(contains(names_, ['_scaleParam_' scaleParam '_']) ...
        & contains(names_, ['_searchmode_' searchModes{ai} '_']) ...
        & contains(names_, ['_fitmode_' modes{ai} '_budget_']));
    budgets = cellfun(@(f) str2double(regexp(f, 'budget_(\d+)', 'tokens', 'once')), names_);
    keep = budgets >= 1 & budgets <= maxRuns;
    names_ = names_(keep);
    budgets = budgets(keep);
    [budgets, order] = sort(budgets);
    names_ = names_(order);
    if numel(budgets) ~= maxRuns || numel(unique(budgets)) ~= maxRuns
        error('loadRepairRuns:runs', 'Expected budgets 1..%d for %s %s %s (scaleParam %s), found %s', ...
            maxRuns, bench, searchModes{ai}, modes{ai}, scaleParam, mat2str(budgets));
    end

    for bi = 1:numel(names_)
        path = fullfile(folder, names_{bi});
        c = load(path);
        g = find(~cellfun(@isempty, {c.fullPopLog.pop}), 1, 'last');
        sortedTS = sortTestSuite(c.mutant.mut_TS);
        origRob = [sortedTS.testCases.rob]';
        popSize = size(c.fullPopLog(1).pop, 1);
        nTests = c.mutant.TS.size;

        if isfield(c, 'calibBestIndLog')
            L = c.calibBestIndLog(g);
        else
            L = c.bestIndLog(g);
        end
        [sr, rob] = settleFinalSR(L.bestRobList, L.bestFitness, origRob, modes{ai}, path);

        if startsWith(modes{ai}, 'cheapincr')
            e = 0;
            for gi = 1:g-1
                e = e + sum(~isinf(c.fullPopLog(gi).popRobList(:)));
            end
            e = e + numel(c.fullPopLog(g).popRobList);
        else
            e = g * popSize * nTests;
        end

        R(ai).budgets(end+1) = budgets(bi);
        R(ai).files{end+1} = path;
        R(ai).newSR(end+1) = sr;
        R(ai).finalRob(:, end+1) = rob;
        R(ai).execTests(end+1) = e;
        if bi == 1
            R(ai).origRob = origRob;
            R(ai).origSR = sum(origRob > 0);
            R(ai).fullBudget = popSize * numel(c.fullPopLog) * nTests;
        end
    end
end
end


function [finalSR, finalRob] = settleFinalSR(bestRob, bestFitness, origRob, fitnessMode, sourcePath)
% The delivered controller replaces the original one only if it passes more
% test inputs. Runs of expdis cut off early may leave unevaluated (NaN)
% entries; they can only fall back to the original controller, which is
% the case when their optimistic fitness is not positive.
origSR = sum(origRob > 0);
if any(~isfinite(bestRob))
    if ~(strcmp(fitnessMode, 'expdis') && bestFitness <= 0)
        error('loadRepairRuns:incomplete', 'Incomplete final robustness list in %s', sourcePath);
    end
    finalSR = origSR;
    finalRob = origRob;
    return;
end
if sum(bestRob > 0) > origSR
    finalSR = sum(bestRob > 0);
    finalRob = bestRob;
else
    finalSR = origSR;
    finalRob = origRob;
end
end
