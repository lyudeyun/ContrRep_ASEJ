function I = loadIsarRuns(isarRoot, isarBench, nRuns)
% LOADISARRUNS Outcome of the ISAR runs of one benchmark.
%
%   I = loadIsarRuns(isarRoot, isarBench, nRuns)
%
% Reads <isarRoot>/<isarBench>/ as written by run_benchmark.py and
% evaluate_testset.py of the ISAR repository (results/contrrep/). Each test
% input of the 100-input suite is a region of its own, so
%   *_sampling_result_broken.csv   - robustness under the original controller
%   run_<k>/sample_checkpoint_<c>.csv - robustness under the controller of
%                                      checkpoint <c>
%   run_<k>/testset_result.json    - final checkpoint of the run (empty if no
%                                    region was repaired, i.e., the original
%                                    controller is kept) and its SR on the
%                                    10^4 held-out inputs
%   run_<k>/simulation_count.json  - number of simulations of the repair
% I has the fields
%   origRob   - robustness of every test input under the original controller
%   finalRob  - robustness under the delivered controller (one column per run)
%   newSR     - number of passing test inputs of the delivered controller
%   execTests - number of simulations of every run
%   valCM     - CM (%) on the held-out inputs of every run

base = fullfile(isarRoot, isarBench);
f = dir(fullfile(base, '*_sampling_result_broken.csv'));
if numel(f) ~= 1
    error('loadIsarRuns:orig', 'Expected one *_sampling_result_broken.csv in %s', base);
end
I.origRob = readRob(fullfile(f.folder, f.name));
I.finalRob = [];
I.newSR = [];
I.execTests = [];
I.valCM = [];

for k = 1:nRuns
    runDir = fullfile(base, sprintf('run_%d', k));
    res = jsondecode(fileread(fullfile(runDir, 'testset_result.json')));
    if isempty(res.checkpoint)
        rob = I.origRob;
    else
        [~, stem] = fileparts(res.checkpoint);              % e.g. tanh_iter_21_region_75
        stem = stem(strfind(stem, 'iter_'):end);
        rob = readRob(fullfile(runDir, ['sample_checkpoint_' stem '.csv']));
    end
    cnt = jsondecode(fileread(fullfile(runDir, 'simulation_count.json')));
    I.finalRob(:, k) = rob;
    I.newSR(k) = sum(rob > 0);
    I.execTests(k) = cnt.total;
    I.valCM(k) = res.SR_after;
end
end


function rob = readRob(path)
% robustness of every test input, ordered by region (= test input index)
t = readtable(path);
[~, order] = sort(t.region);
rob = t.result(order);
end
