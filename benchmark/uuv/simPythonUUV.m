function [rob, taus, traj_nn_in, traj_nn_out, traj_pos_x, traj_pos_y] = simPythonUUV(initY, initHeading, nnPath)
% SIMPYTHONUUV Simulates UUV system behavior using a Python script.
%
% Inputs:
%   initY       - Initial y-axis position of the UUV (must be in [12, 22])
%   initHeading - Initial heading angle (must be in [10, 30] degrees)
%   nnPath      - Path to YAML file containing the neural network weights
%
% Outputs:
%   rob         - STL robustness value
%   taus        - Time horizon used in the specification (e.g., 110)
%   traj_nn_in  - [2 × T] NN inputs at each step (initY and heading)
%   traj_nn_out - [1 × T] NN outputs (control signals)
%   traj_pos_x  - [1 × (T+1)] x trajectory of the UUV
%   traj_pos_y  - [1 × (T+1)] y trajectory of the UUV

% Check if all required inputs are provided
if nargin < 3
    error('initY, initHeading, and nnPath must all be provided!');
end

% Check validity of initial conditions
isYValid = initY >= 12 && initY <= 22;
isHValid = initHeading >= 10 && initHeading <= 30;

if ~isYValid || ~isHValid
    fprintf('Invalid input: initY = %.2f, initHeading = %.2f\n', initY, initHeading);
    error('Input parameters are out of the valid range!');
end

% Build the system command to run Python simulator
cmd = sprintf('python3 ./benchmark/uuv/sim_uuv.py --init_y %.6f --init_heading %.6f --nn_path "%s"', ...
    initY, initHeading, nnPath);

% Execute the command
[status, cmdout] = system(cmd);

if status == 0
    % Parse simulation output
    diagInfo     = jsondecode(cmdout);
    rob          = diagInfo.rob;
    taus         = diagInfo.taus;
    traj_nn_in_1 = diagInfo.traj_nn_in_1';
    traj_nn_in_2 = diagInfo.traj_nn_in_2';
    traj_nn_out  = diagInfo.traj_nn_out';
    traj_pos_x   = diagInfo.traj_pos_x';
    traj_pos_y   = diagInfo.traj_pos_y';

    % Combine NN inputs into a single matrix
    traj_nn_in = [traj_nn_in_1; traj_nn_in_2];
else
    error('UUV simulation failed with error:\n%s', cmdout);
end
end