import os
import numpy as np
import json
import yaml
import argparse
from uuv import UUV_Control_NN, load_model_dict, uuv_simulate, uuv_robustness
from scipy.io import savemat

# Parse command-line arguments for UUV simulation settings
parser = argparse.ArgumentParser(description='UUV simulation')
parser.add_argument('--init_y', type=float, default=20.0, help='Initial Y position')
parser.add_argument('--init_heading', type=float, default=15.0, help='Initial heading angle (degrees)')
parser.add_argument('--nn_path', type=str, default='uuv_tanh_2_15_2x32_broken.yml', help='Path to the YAML file of NN controller')
args = parser.parse_args()

# Step 1: Load the pre-trained controller model
# Always resolve to absolute path (relative to current working directory)
nn_path = os.path.abspath(args.nn_path)

# Load from YAML file
with open(nn_path, 'rb') as f:
    model_dict = yaml.safe_load(f)

# Create model instance
net = UUV_Control_NN()

# Load parameters into the model
load_model_dict(model_dict, net)

# print(net)

# Step 2: Simulate the system using the controller
# For UUV:
init_y = args.init_y                # Get initial Y position from command-line arguments
init_heading = args.init_heading    # Get initial heading angle from command-line arguments 
traj_nn_in_1, traj_nn_in_2, traj_nn_out, traj_pos_x, traj_pos_y = uuv_simulate(net=net, init_global_heading_deg=init_heading, init_pos_y=init_y)

# Step 3: Evaluate the STL specification robustness of the trajectory
# For UUV:
rob, taus = uuv_robustness(traj_pos_y)

# for FL
diagInfo = {
    'rob': rob,
    'taus': taus,
    'traj_nn_in_1': traj_nn_in_1,
    'traj_nn_in_2': traj_nn_in_2,
    # numpy.float32 -> float
    'traj_nn_out': [float(v) for v in traj_nn_out],
    'traj_pos_x': traj_pos_x,
    'traj_pos_y': traj_pos_y
}

# Output JSON to stdout (can be captured by MATLAB)
print(json.dumps(diagInfo))