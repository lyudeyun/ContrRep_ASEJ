import numpy as np
import torch
import torch.nn as nn
import yaml
import os
import scipy.io as sio
import pandas as pd

""" Controller network utils """

# PyTorch models for UUV controller net
class UUV_Control_NN(nn.Module):

    def __init__(self, layer_1_size=32, layer_2_size=32):
        super(UUV_Control_NN, self).__init__()
        self.fc1 = nn.Linear(2, layer_1_size)
        self.fc2 = nn.Linear(layer_1_size, layer_2_size)
        self.fc3 = nn.Linear(layer_2_size, 1)

    def forward(self, x):
        x = torch.tanh(self.fc1(x))
        x = torch.tanh(self.fc2(x))
        x = torch.tanh(self.fc3(x))
        return x


# Load yaml to torch model
def load_model_dict(model_dict: dict, network: nn.Module):
    def normalize_keys(d: dict) -> dict:
        """Convert keys like 'x1', 'x_1' or '1' to int."""
        new_d = {}
        for k, v in d.items():
            if isinstance(k, int):
                new_d[k] = v
            elif isinstance(k, str) and k.isdigit():
                new_d[int(k)] = v
            elif isinstance(k, str) and k.startswith('x_') and k[2:].isdigit():
                new_d[int(k[2:])] = v
            elif isinstance(k, str) and k.startswith('x') and k[1:].isdigit():
                new_d[int(k[1:])] = v
            else:
                raise ValueError(f"Unsupported key format: {k}")
        return new_d

    def to_tensor(val):
        """Convert to tensor; if float, wrap in list first."""
        if isinstance(val, float):
            return torch.FloatTensor([val])
        return torch.FloatTensor(val)

    weights = normalize_keys(model_dict['weights'])
    offsets = normalize_keys(model_dict['offsets'])

    state_dict = {
        'fc1.weight': torch.FloatTensor(weights[1]),
        'fc1.bias': to_tensor(offsets[1]),
        'fc2.weight': torch.FloatTensor(weights[2]),
        'fc2.bias': to_tensor(offsets[2]),
        'fc3.weight': torch.FloatTensor(weights[3]).reshape(1, -1),  # Ensure shape is [1, N]
        'fc3.bias': to_tensor(offsets[3])
    }

    network.load_state_dict(state_dict)

# Dump torch model to yaml
def dump_model_dict(filename, network: nn.Module):
    model_dict = {}
    model_dict['activations'] = {}
    if isinstance(network, UUV_Control_NN):
        model_dict['activations'][1] = 'Tanh'
        model_dict['activations'][2] = 'Tanh'
    else:
        raise NotImplementedError
    model_dict['activations'][3] = 'Tanh'
    model_dict['weights'] = {}
    model_dict['offsets'] = {}
    for layer in [1, 2, 3]:
        model_dict['weights'][layer] = network.state_dict()[f'fc{layer}.weight'].tolist()
        model_dict['offsets'][layer] = network.state_dict()[f'fc{layer}.bias'].tolist()
    with open(filename, 'w') as f:
        yaml.dump(model_dict, f)
    return


""" UUV utils """
# Simulate, init_global_heading is in degrees
def uuv_simulate(net: UUV_Control_NN, init_global_heading_deg, init_pos_y):
    
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    mat_path = os.path.join(cur_dir, 'uuv_model_oneHz.mat')
    # Dynamics coeff matrices
    coeffs = sio.loadmat(mat_path)
    A, B, C, D = coeffs['A'], coeffs['B'], coeffs['C'], coeffs['D']
    init_global_heading = init_global_heading_deg / 180 * np.pi
    x = np.array([[0], [0], [0], [0]])
    u = np.array([[0], [0.48556], [45.0]])
    pos_x = 0.0
    pos_y = init_pos_y

    traj_pos_x = [pos_x]
    traj_pos_y = [pos_y]

    traj_nn_in_1 = []
    traj_nn_in_2 = []
    traj_nn_out = []

    for i in range(30):

        # Compute y and x
        y = np.dot(C, x) + np.dot(D, u)
        x = np.dot(A, x) + np.dot(B, u)

        # Update pos_x, pos_y
        heading = y[0][0]
        heading = heading if heading < np.pi else heading - 2 * np.pi
        global_heading = heading + init_global_heading
        pos_x += y[1][0] * np.cos(global_heading)
        pos_y -= y[1][0] * np.sin(global_heading)

        traj_pos_x += [pos_x]
        traj_pos_y += [pos_y]

        # Control u update
        pipe_heading = -1.0 * global_heading
        stdb_range = pos_y / np.cos(global_heading)

        nn_inputs = torch.FloatTensor([pipe_heading, stdb_range])
        nn_out = net(nn_inputs).detach().numpy()[0]

        traj_nn_in_1.append(pipe_heading)
        traj_nn_in_2.append(stdb_range)
        traj_nn_out.append(nn_out)
        
        # Early stop
        if pos_y < 10 or pos_y > 50 or pos_x < -10 or pos_x > 400:
            break

        heading_delta = np.radians(5) * nn_out
        abs_heading = heading_delta + heading
        abs_heading = abs_heading if abs_heading < np.pi else abs_heading - 2 * np.pi
        u = np.array([[abs_heading], [0.48556], [45.0]])
        
    return traj_nn_in_1, traj_nn_in_2, traj_nn_out, traj_pos_x, traj_pos_y


# STL robustness of G_{[0, 30]} (pos_y \leq 50 \land pos_y \geq 10)
# for each pos_y, find min(50 - pos_y, pos_y - 10)
def uuv_robustness(traj_pos_y):
    scores = [min(50 - pos_y, pos_y - 10) for pos_y in traj_pos_y]
    taus = len(traj_pos_y) - 1
    return np.min(scores), taus