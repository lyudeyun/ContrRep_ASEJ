function [rob, taus, traj_nn_in_1, traj_nn_in_2, traj_nn_out, trajPos, trajVel] = simMatlabMC(initPos, initVel, nnPath)
% SIMMATLABMC Simulates the Mountain Car (MC) system using a neural network controller.
%
% Inputs:
%   initPos  - Initial position of the car
%   initVel  - Initial velocity of the car
%   nnPath   - Path to the YAML file containing the NN weights and biases
%
% Outputs:
%   rob             - STL robustness value: max(trajPosX) - 0.45
%   taus            - Time bound for STL property (110)
%   traj_nn_in_1    - Position inputs to NN at each step (1×110)
%   traj_nn_in_2    - Velocity inputs to NN at each step (1×110)
%   traj_nn_out     - NN outputs (control signals) at each step (1×110)
%   trajPos         - Position trajectory of the car (1×111)
%   trajVel         - Velocity trajectory of the car (1×111)

% Load neural network parameters from YAML
mcNet = convertMCYamlToMat(nnPath);

steepness = 0.0025;    % Slope of the hill
len = 111;             % Simulation length (0 to 110)

% Initialize trajectories
trajPos = zeros(1, len);
trajVel = zeros(1, len);
traj_nn_in_1 = zeros(1, len - 1);
traj_nn_in_2 = zeros(1, len - 1);
traj_nn_out = zeros(1, len - 1);

% Set initial state
trajPos(1) = initPos;
trajVel(1) = initVel;

for i = 2:len
    % Update position using previous velocity
    trajPos(i) = trajPos(i-1) + trajVel(i-1);

    % Prepare NN inputs: [position; velocity]
    nn_inputs = [trajPos(i-1); trajVel(i-1)];

    % Record inputs for logging
    traj_nn_in_1(i-1) = trajPos(i-1);
    traj_nn_in_2(i-1) = trajVel(i-1);

    % NN forward pass
    z1 = mcNet.IW{1,1} * nn_inputs + mcNet.b{1};
    a1 = sigmoid(z1);
    z2 = mcNet.LW{2,1} * a1 + mcNet.b{2};
    a2 = sigmoid(z2);
    z3 = mcNet.LW{3,2} * a2 + mcNet.b{3};
    nn_out = tanh(z3);  % Output control signal

    % Record NN output
    traj_nn_out(i-1) = nn_out;

    % Update velocity based on physics and control signal
    trajVel(i) = trajVel(i-1) + 0.0015 * nn_out - steepness * cos(3 * trajPos(i-1));

    % Velocity saturation
    if trajVel(i) > 0.07
        trajVel(i) = 0.07;
    elseif trajVel(i) < -0.07
        trajVel(i) = -0.07;
    end

    % Position saturation
    if trajPos(i) > 0.6
        trajPos(i) = 0.6;
    elseif trajPos(i) < -1.2
        trajPos(i) = -1.2;
    end

    % Edge condition: reset velocity if hitting the leftmost boundary
    if trajPos(i) == -1.2 && trajVel(i) < 0
        trajVel(i) = 0;
    end
end

% STL robustness: ensure position eventually reaches ≥ 0.45
taus = 110;
rob = max(trajPos) - 0.45;
end

% Sigmoid activation function
function y = sigmoid(x)
y = 1 ./ (1 + exp(-x));
end