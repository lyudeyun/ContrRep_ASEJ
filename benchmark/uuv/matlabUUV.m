function [rob, taus, traj_nn_in_1, traj_nn_in_2, traj_nn_out, traj_pos_x, traj_pos_y] = matlabUUV(init_pos_y, init_global_heading_deg, nnPath)

uuvNet = convertUUVYamlToMat(nnPath);

% Load model coefficients
mat_path = which('uuv_model_oneHz.mat');
data = load(mat_path);
A = data.A; B = data.B; C = data.C; D = data.D;

% Initial conditions
init_global_heading = init_global_heading_deg / 180 * pi;
x = [0; 0; 0; 0];
u = [0; 0.48556; 45.0];
pos_x = 0.0;
pos_y = init_pos_y;

% Trajectory records
traj_pos_x = pos_x;
traj_pos_y = pos_y;
traj_nn_in_1 = [];
traj_nn_in_2 = [];
traj_nn_out = [];

for i = 1:30
    % Compute y and update x
    y = C * x + D * u;
    x = A * x + B * u;
    
    % Update positions
    heading = y(1);
    if heading > pi
        heading = heading - 2*pi;
    end
    global_heading = heading + init_global_heading;
    pos_x = pos_x + y(2) * cos(global_heading);
    pos_y = pos_y - y(2) * sin(global_heading);

    traj_pos_x(end+1) = pos_x;
    traj_pos_y(end+1) = pos_y;

    % NN control input
    pipe_heading = -1.0 * global_heading;
    stdb_range = pos_y / cos(global_heading);
    nn_inputs = [pipe_heading, stdb_range];

    % NN inference
    z1 = uuvNet.IW{1,1} * nn_inputs' + uuvNet.b{1};
    a1 = tanh(z1);
    z2 = uuvNet.LW{2,1} * a1 + uuvNet.b{2};
    a2 = tanh(z2);
    z3 = uuvNet.LW{3,2} * a2 + uuvNet.b{3};
    nn_out = tanh(z3);

    traj_nn_in_1(end+1) = pipe_heading;
    traj_nn_in_2(end+1) = stdb_range;
    traj_nn_out(end+1) = nn_out;

    % Early stop
    if pos_y < 10 || pos_y > 50 || pos_x < -10 || pos_x > 400
        break;
    end

    heading_delta = deg2rad(5) * nn_out;
    abs_heading = heading_delta + heading;
    if abs_heading > pi
        abs_heading = abs_heading - 2*pi;
    end
    u = [abs_heading; 0.48556; 45.0];
end

% STL robustness: G_[0,30](pos_y <= 50 and pos_y >= 10)
scores = arrayfun(@(y) min(50 - y, y - 10), traj_pos_y);
rob = min(scores);
taus = length(traj_pos_y) - 1;

end