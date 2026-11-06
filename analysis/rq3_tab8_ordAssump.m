% === RQ3, Table 8: validity of the ordering assumption behind the approximate fitness ===
% The cheapincr fitness modes (ContrRep-Fast) skip test inputs by assuming, on
% the robustness-sorted suite, that
%   * failing side: once a failing test is not repaired, the more severely
%     violated ones are not repaired either  (skipped entries recorded as -Inf)
%   * passing side: once a passing test is preserved, the more robust ones are
%     preserved as well                       (skipped entries recorded as +Inf)
% Calibration re-simulates the skipped entries of every individual of the
% calibrated generations, so fullPopLog (approximate) and calibFullPopLog
% (exact) can be compared entry by entry.
%
% Metrics, pooled over all individuals of all calibrated generations of all runs:
%   Skipped - fraction of test inputs whose outcome is assumed, not simulated
%   V-      - fraction of skipped failing tests that are indeed still failing
%   V+      - fraction of skipped passing tests that are indeed still passing
%   SA      - fraction of calibrated generations in which the individual with the
%             highest approximate number of passing tests also has the highest
%             exact number of passing tests (ties among the approximate best are
%             resolved in favour of the best exact one)
clear; clc;
warning('off', 'all');
root = repoRoot();

scaleParam = '2';
maxBudget  = 10;
fitModes   = {'cheapincrdis', 'cheapincrcon1', 'cheapincrcon3'};

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
res = nan(nC, 4);            % Skipped, V-, V+, SA (in %)
nRuns = zeros(nC, 1);

for ri = 1:nC
    dirPath = fullfile(root, 'results', caseTable{ri,2}, 'DE', caseTable{ri,3});
    files = dir(fullfile(dirPath, [caseTable{ri,4} '_bug_*.mat']));

    nNeg = 0; nNegHold = 0; nPos = 0; nPosHold = 0; nSkip = 0; nAll = 0;
    nGen = 0; nAgree = 0;

    for fi = 1:numel(files)
        fn = files(fi).name;
        if ~contains(fn, ['_tssize_100_scaleParam_' scaleParam '_']), continue; end
        fm = regexp(fn, 'fitmode_(\w+?)_budget', 'tokens', 'once');
        if isempty(fm) || ~any(strcmp(fm{1}, fitModes)), continue; end
        b = str2double(regexp(fn, '(?<=_budget_)\d+', 'match', 'once'));
        if b > maxBudget, continue; end

        c = load(fullfile(files(fi).folder, fn), 'fullPopLog', 'calibFullPopLog');
        if ~isfield(c, 'calibFullPopLog')
            fprintf(2, 'WARNING not calibrated, skipped: %s\n', fn);
            continue;
        end
        nRuns(ri) = nRuns(ri) + 1;

        for g = 1:numel(c.calibFullPopLog)
            if isempty(c.calibFullPopLog(g).pop), continue; end
            A = c.fullPopLog(g).popRobList;        % approximate, +-Inf = assumed
            T = c.calibFullPopLog(g).popRobList;   % exact

            negMask = (A == -Inf);
            posMask = (A ==  Inf);
            nNeg     = nNeg     + nnz(negMask);
            nNegHold = nNegHold + nnz(negMask & T < 0);
            nPos     = nPos     + nnz(posMask);
            nPosHold = nPosHold + nnz(posMask & T > 0);
            nSkip    = nSkip    + nnz(negMask | posMask);
            nAll     = nAll     + numel(A);

            apx = sum(A > 0, 1);                   % +Inf counts as passing
            tru = sum(T > 0, 1);
            best = (apx == max(apx));
            nGen = nGen + 1;
            nAgree = nAgree + (max(tru(best)) == max(tru));
        end
    end

    res(ri, :) = 100 * [nSkip / nAll, nNegHold / nNeg, nPosHold / nPos, nAgree / nGen];
end

names = {'Skipped', 'Vneg', 'Vpos', 'SA'};
disp(array2table(round(res, 1), 'VariableNames', names, 'RowNames', caseTable(:,2)));
disp('calibrated runs per benchmark:'); disp(array2table(nRuns, 'RowNames', caseTable(:,2)));

% --- LaTeX rows ---
L = strings(0, 1);
for ri = 1:nC
    L(end+1) = sprintf('%s & %.1f & %.1f & %.1f & %.1f \\\\', caseTable{ri,1}, res(ri,:)); %#ok<AGROW>
end
fprintf('\n%s\n', strjoin(L, newline));
