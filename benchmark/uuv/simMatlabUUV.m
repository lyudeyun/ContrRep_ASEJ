function [rob, taus, traj_nn_in, traj_nn_out, traj_pos_x, traj_pos_y] = simMatlabUUV(init_pos_y, init_global_heading_deg, nnPath)
% MATLABUUV Simulates UUV dynamics using a trained neural network controller.
%
% Inputs:
%   init_pos_y              - Initial Y-axis position of the UUV
%   init_global_heading_deg - Initial global heading (degrees)
%   nnPath                  - Path to the YAML file storing the trained NN
%
% Outputs:
%   rob           - STL robustness value (pos_y should stay within [10, 50])
%   taus          - Time steps of simulation (<= 30)
%   traj_nn_in_1  - NN input: pipe heading at each step
%   traj_nn_in_2  - NN input: starboard range at each step
%   traj_nn_out   - NN output: heading adjustment command at each step
%   traj_pos_x    - UUV X position trajectory
%   traj_pos_y    - UUV Y position trajectory

% Load neural network from YAML
uuvNet = convertUUVYamlToMat(nnPath);

% Load UUV dynamic model (discretized)
mat_path = which('uuv_model_oneHz.mat');
data = load(mat_path);
A = data.A; B = data.B; C = data.C; D = data.D;

% Initial heading in radians
init_global_heading = deg2rad(init_global_heading_deg);

% Initial system state: [heading; velocity; ...]
x = [0; 0; 0; 0];

% Initial control input: [heading; surge; dive]
u = [0; 0.48556; 45.0];

% Initial position
pos_x = 0.0;
pos_y = init_pos_y;

% Initialize trajectory logs
traj_pos_x = pos_x;
traj_pos_y = pos_y;
traj_nn_in_1 = [];
traj_nn_in_2 = [];
traj_nn_out = [];

for i = 1:30
    % System dynamics: y = output, x = updated state
    y = C * x + D * u;
    x = A * x + B * u;

    % Extract heading and calculate global heading
    heading = y(1);
    if heading > pi
        heading = heading - 2 * pi;
    end
    global_heading = heading + init_global_heading;

    % Update position
    pos_x = pos_x + y(2) * cos(global_heading);
    pos_y = pos_y - y(2) * sin(global_heading);
    traj_pos_x(end + 1) = pos_x;
    traj_pos_y(end + 1) = pos_y;

    % NN inputs
    pipe_heading = -global_heading;
    stdb_range = pos_y / cos(global_heading);
    nn_inputs = [pipe_heading; stdb_range];

    % NN inference (3-layer tanh NN)
    z1 = uuvNet.IW{1,1} * nn_inputs + uuvNet.b{1};
    a1 = tanh(z1);
    z2 = uuvNet.LW{2,1} * a1 + uuvNet.b{2};
    a2 = tanh(z2);
    z3 = uuvNet.LW{3,2} * a2 + uuvNet.b{3};
    nn_out = tanh(z3);

    traj_nn_in_1(end + 1) = pipe_heading;
    traj_nn_in_2(end + 1) = stdb_range;
    traj_nn_out(end + 1) = nn_out;

    % Early termination if out of bounds
    if pos_y < 10 || pos_y > 50 || pos_x < -10 || pos_x > 400
        break;
    end

    % Update heading input based on NN output
    heading_delta = deg2rad(5) * nn_out;
    abs_heading = heading + heading_delta;
    if abs_heading > pi
        abs_heading = abs_heading - 2 * pi;
    end
    u = [abs_heading; 0.48556; 45.0]; % surge and dive fixed
end

traj_nn_in = [traj_nn_in_1; traj_nn_in_2];

% STL robustness: G_[0,30](pos_y ∈ [10, 50])
scores = arrayfun(@(y) min(50 - y, y - 10), traj_pos_y);
rob = min(scores);
taus = length(traj_pos_y) - 1;
end