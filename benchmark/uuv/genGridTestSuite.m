% function [] = genGridTestSuite(in_range)

gridNumY = 100;
gridNumH = 20;

testCaseNum = gridNumY * gridNumH;

testCases(testCaseNum, 1) = struct('sysInputs', [], 'nnInputs', [], 'nnOutputs', [],  'rob', [], 'taus', []);

yRange = [12,22];
hRange = [10,30];

samples = gridSampling2D(yRange(1), yRange(2), hRange(1), hRange(2), gridNumY, gridNumH);

parfor tci = 1:testCaseNum
    [rob, taus, traj_nn_in, traj_nn_out, traj_pos_x, traj_pos_y] = simMatlabUUV(samples(tci,1), samples(tci,2), 'uuv_tanh_2_15_2x32_broken.yml');
    testCases(tci).sysInputs = samples(tci,:)';
    testCases(tci).nnInputs = traj_nn_in;
    testCases(tci).nnOutputs = traj_nn_out;
    testCases(tci).rob = rob;
    testCases(tci).taus = taus;
end

testSuite.sn = sum([testCases.rob] > 0);
testSuite.size = testCaseNum;
testSuite.testCases = testCases;