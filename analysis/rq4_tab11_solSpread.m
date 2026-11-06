% === RQ4, Table 11: where the repairs found by ContrRep lie in the search space ===
% The scale parameter s bounds the search space of every suspicious weight
% (obtainBound). To explain why ContrRep is insensitive to s while Random is
% not, this script locates the delivered repairs inside these bounds.
%
% For every benchmark and every s, it takes the delivered patch of each DE run
% (6 fitness modes x 10 runs): the best individual of the last generation, or
% the best calibrated one for the cheapincr modes, i.e., the patch whose CM is
% reported. Pooling the K weights of all these patches, it computes
%   InRange1.5 - percentage of repaired weights that lie within the bounds
%                obtained with s = 1.5 (the narrowest range studied)
%   RelChange  - median relative change |x - w0| / |w0| of the repaired weights
%                with respect to their original values w0
clear; clc;
warning('off', 'all');
root = repoRoot();
addpath(genpath(fullfile(root, 'util')));

scaleParams = {'1.5', '2', '3'};
maxBudget   = 10;
fitModes    = {'expdis', 'expcon1', 'expcon3', 'cheapincrdis', 'cheapincrcon1', 'cheapincrcon3'};

% row label, results folder, DE subfolder, model file prefix
caseTable = {
 'ACC$^{\C_{1}}$',  'ACC1_Phi1', 'tops_10_popSize_20_gen_50', 'ACC4_FFNN_trainbfg_15_15_15_ep_100_Nor_20250527'
 'ACC$^{\C_{2}}$',  'ACC1_Phi2', 'tops_10_popSize_20_gen_50', 'ACC5v_FFNN_traingdx_15_15_15_ep_50_Nor_20250702'
 'ACC$^{\C_{3}}$',  'ACC2_Phi1', 'tops_35_popSize_70_gen_50', 'ACC4_FFNN_trainoss_30_30_30_ep_100_Nor_20250528'
 'ACC$^{\C_{4}}$',  'ACC2_Phi2', 'tops_35_popSize_70_gen_50', 'ACC5v_FFNN_traincgf_30_30_30_ep_50_Nor_20250704'
 'AFC$^{\C_{5}}$',  'AFC1_Phi1', 'tops_10_popSize_20_gen_50', 'AFC1_FFNN_trainscg_15_15_15_ep_1000_Nor_20250518'
 'AFC$^{\C_{6}}$',  'AFC1_Phi2', 'tops_10_popSize_20_gen_50', 'AFC2_FFNN_trainscg_15_15_15_ep_1000_Nor_20250717'
 'AFC$^{\C_{7}}$',  'AFC2_Phi1', 'tops_15_popSize_30_gen_50', 'AFC1_FFNN_trainrp_15_15_15_15_ep_1000_Nor_20250519'
 'AFC$^{\C_{8}}$',  'AFC2_Phi2', 'tops_15_popSize_30_gen_50', 'AFC2_FFNN_trainscg_15_15_15_15_ep_500_Nor_20250717'
 'UUV$^{\C_{9}}$',  'UUV',       'tops_20_popInitMode_hybridGuass_popSize_40_gen_50', 'uuv_tanh_2_15_2x32_broken_cp'
 'MC$^{\C_{10}}$',  'MC',        'tops_5_popInitMode_hybridGuass_popSize_10_gen_50',  'mc_sig_2x16_broken_cp'
 };

nC = size(caseTable, 1);
nS = numel(scaleParams);
inRange15 = nan(nC, nS);     % percentage within the s = 1.5 bounds
relChange = nan(nC, nS);     % median |x - w0| / |w0|
nPatches  = zeros(nC, nS);

for ri = 1:nC
    dirPath = fullfile(root, 'results', caseTable{ri,2}, 'DE', caseTable{ri,3});
    files = dir(fullfile(dirPath, [caseTable{ri,4} '_bug_*.mat']));

    for si = 1:nS
        X = [];          % delivered patches, one row per run
        w0 = [];
        for fi = 1:numel(files)
            fn = files(fi).name;
            if ~contains(fn, ['_tssize_100_scaleParam_' scaleParams{si} '_']), continue; end
            fm = regexp(fn, 'fitmode_(\w+?)_budget', 'tokens', 'once');
            if isempty(fm) || ~any(strcmp(fm{1}, fitModes)), continue; end
            b = str2double(regexp(fn, '(?<=_budget_)\d+', 'match', 'once'));
            if b > maxBudget, continue; end

            c = load(fullfile(files(fi).folder, fn), 'bestIndLog', 'calibBestIndLog', 'fullPopLog', 'spsWeights');
            g = find(~cellfun(@isempty, {c.fullPopLog.pop}), 1, 'last');
            if startsWith(fm{1}, 'cheapincr')
                if ~isfield(c, 'calibBestIndLog')
                    error('not calibrated: %s', fn);
                end
                patch = c.calibBestIndLog(g).bestInd;
            else
                patch = c.bestIndLog(g).bestInd;
            end
            X(end+1, :) = patch(:)'; %#ok<AGROW>
            spsWeights = c.spsWeights;
            w0 = spsWeights(:, 4)';
        end
        nPatches(ri, si) = size(X, 1);

        [lb15, ub15] = obtainBound(spsWeights, 1.5);
        inside = X >= lb15 - 1e-12 & X <= ub15 + 1e-12;
        inRange15(ri, si) = 100 * mean(inside(:));

        rel = abs(X - w0) ./ abs(w0);
        relChange(ri, si) = median(rel(:));
    end
end

disp('patches per benchmark and scale parameter:');
disp(array2table(nPatches, 'VariableNames', strcat('s', strrep(scaleParams, '.', '_')), 'RowNames', caseTable(:,2)));
disp('InRange1.5 (%):');
disp(array2table(round(inRange15, 1), 'VariableNames', strcat('s', strrep(scaleParams, '.', '_')), 'RowNames', caseTable(:,2)));
disp('RelChange (median):');
disp(array2table(round(relChange, 2), 'VariableNames', strcat('s', strrep(scaleParams, '.', '_')), 'RowNames', caseTable(:,2)));

% --- LaTeX rows: InRange1.5 at s = 2 and 3, RelChange at s = 1.5, 2 and 3 ---
L = strings(0, 1);
for ri = 1:nC
    L(end+1) = sprintf('%s & %.1f & %.1f & %.2f & %.2f & %.2f \\\\', caseTable{ri,1}, ...
        inRange15(ri, 2), inRange15(ri, 3), relChange(ri, 1), relChange(ri, 2), relChange(ri, 3)); %#ok<AGROW>
end
fprintf('\n%s\n', strjoin(L, newline));
