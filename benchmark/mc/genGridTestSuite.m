gridNumPos = 10;
gridNumVel = 10;

testCaseNum = gridNumPos * gridNumVel;

testCases(testCaseNum, 1) = struct('sysInputs', [], 'nnInputs', [], 'nnOutputs', [], 'rob', [], 'taus', [], 'trajPos', [], 'trajVel', []);

posRange = [-0.505,0.395];
velRange = [-0.055,0.045];

samples = gridSampling2D(posRange(1), posRange(2), velRange(1), velRange(2), gridNumPos, gridNumVel);

parfor tci = 1:testCaseNum
    [rob, taus, traj_nn_in, traj_nn_out, traj_pos, traj_vel] = simPyMC(samples(tci,1),samples(tci,2), 'mc_sig_2x16_broken.yml');
    testCases(tci).sysInputs = samples(tci,:)';
    testCases(tci).nnInputs = traj_nn_in;
    testCases(tci).nnOutputs = traj_nn_out;
    testCases(tci).rob = rob;
    testCases(tci).taus = taus;
    testCases(tci).trajPos = traj_pos;
    testCases(tci).trajVel = traj_vel;
end

testSuite.sn = sum([testCases.rob] > 0);
testSuite.size = testCaseNum;
testSuite.testCases = testCases;