% Generate nested 50- and 75-trace suites from the existing 100-trace suites.

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
seed = 1;
targetSizes = [50, 75];

benchmarkNames = {
    'ACC1 Phi1'
    'ACC1 Phi2'
    'ACC2 Phi1'
    'ACC2 Phi2'
    'AFC1 Phi1'
    'AFC1 Phi2'
    'AFC2 Phi1'
    'AFC2 Phi2'
};

baseFiles = {
    'FLRepBenchGen/ACC1_Phi1/ACC4_drel_10_vego_10_30/ACC4_FFNN_trainbfg_15_15_15_ep_100_Nor_20250527/ACC4_FFNN_trainbfg_15_15_15_ep_100_Nor_20250527_testCaseNum_100.mat'
    'FLRepBenchGen/ACC1_Phi2/ACC5v_drel_15_vego_15/ACC5v_FFNN_traingdx_15_15_15_ep_50_Nor_20250702/ACC5v_FFNN_traingdx_15_15_15_ep_50_Nor_20250702_testCaseNum_100.mat'
    'FLRepBenchGen/ACC2_Phi1/ACC4_drel_10_vego_10_30/ACC4_FFNN_trainoss_30_30_30_ep_100_Nor_20250528/ACC4_FFNN_trainoss_30_30_30_ep_100_Nor_20250528_testCaseNum_100.mat'
    'FLRepBenchGen/ACC2_Phi2/ACC5v_drel_15_vego_15/ACC5v_FFNN_traincgf_30_30_30_ep_50_Nor_20250704/ACC5v_FFNN_traincgf_30_30_30_ep_50_Nor_20250704_testCaseNum_100.mat'
    'FLRepBenchGen/AFC1_Phi1/AFC1_FFNN_trainscg_15_15_15_ep_1000_Nor_20250518/AFC1_FFNN_trainscg_15_15_15_ep_1000_Nor_20250518_testCaseNum_100.mat'
    'FLRepBenchGen/AFC1_Phi2/AFC2_FFNN_trainscg_15_15_15_ep_1000_Nor_20250717/AFC2_FFNN_trainscg_15_15_15_ep_1000_Nor_20250717_testCaseNum_100.mat'
    'FLRepBenchGen/AFC2_Phi1/AFC1_FFNN_trainrp_15_15_15_15_ep_1000_Nor_20250519/AFC1_FFNN_trainrp_15_15_15_15_ep_1000_Nor_20250519_testCaseNum_100.mat'
    'FLRepBenchGen/AFC2_Phi2/AFC2_FFNN_trainscg_15_15_15_15_ep_500_Nor_20250717/AFC2_FFNN_trainscg_15_15_15_15_ep_500_Nor_20250717_testCaseNum_100.mat'
};

for fileIdx = 1:numel(baseFiles)
    baseFile = fullfile(repoRoot, baseFiles{fileIdx});
    data = load(baseFile, 'testSuite');
    baseSuite = data.testSuite;
    baseCases = baseSuite.testCases(:);

    assert(baseSuite.size == 100 && numel(baseCases) == 100, ...
        'Expected exactly 100 traces in %s.', baseFile);
    assert(baseSuite.sn == sum([baseCases.rob] > 0), ...
        'Inconsistent sn metadata in %s.', baseFile);

    rng(seed, 'twister');
    safeIdx = find([baseCases.rob] > 0);
    unsafeIdx = find([baseCases.rob] <= 0);
    safeOrder = safeIdx(randperm(numel(safeIdx)));
    unsafeOrder = unsafeIdx(randperm(numel(unsafeIdx)));

    [outputDir, baseName] = fileparts(baseFile);
    namePrefix = regexprep(baseName, '_testCaseNum_100$', '');

    for targetSize = targetSizes
        targetSN = round(targetSize * baseSuite.sn / baseSuite.size);
        targetUnsafe = targetSize - targetSN;
        selectedIdx = [safeOrder(1:targetSN), ...
            unsafeOrder(1:targetUnsafe)];
        selectedIdx = sort(selectedIdx);

        testSuite = baseSuite;
        testSuite.testCases = baseCases(selectedIdx);
        testSuite.size = numel(testSuite.testCases);
        testSuite.sn = sum([testSuite.testCases.rob] > 0);

        outputName = sprintf('%s_testCaseNum_%d.mat', namePrefix, targetSize);
        outputPath = fullfile(outputDir, outputName);
        assert(~isfile(outputPath), 'Output already exists: %s.', outputPath);
        save(outputPath, 'testSuite');

        fprintf('%s: saved size=%d, sn=%d to %s\n', ...
            benchmarkNames{fileIdx}, testSuite.size, testSuite.sn, outputPath);
    end
end
