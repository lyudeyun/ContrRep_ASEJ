load('MC_Phi_1_FFNN_16_16_XV_10_10_20250609.mat');

for tci = 1:100
    sysInputs = testSuite.testCases(tci).sysInputs;
    [rob, taus, traj_nn_in_1, traj_nn_in_2, traj_nn_out, trajPosX, trajVel] = simMatlabMC(sysInputs(1), sysInputs(2), 'mc_sig_2x16_broken_cp.yml');

    if abs(rob - testSuite.testCases(tci).rob) > 1e-5
        disp(tci);
        disp(rob);
        disp(testSuite.testCases(tci).rob);
    end

    % diffs = abs(trajPosX - testSuite.testCases(tci).trajPos);
    % if any(diffs > 1e-4)
    %     disp(['Test case index: ', num2str(tci)]);
    %     disp('Differences > 1e-4:');
    %     disp(diffs(diffs > 1e-4));
    % end
end