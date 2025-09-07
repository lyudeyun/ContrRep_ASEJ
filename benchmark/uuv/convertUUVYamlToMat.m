function [uuvNet] = convertUUVYamlToMat(yamlFile)
% UUVNETYAML2MAT converts a UUV neural network defined in a YAML file 
% into a MATLAB struct compatible with MATLAB's NN toolbox conventions.
%
% Input:
%   yamlFile - path to the YAML file containing the UUV network definition
%
% Output:
%   uuvNet - struct with fields:
%       .name       - (empty) optional network name
%       .numlayers  - number of layers in the network (set to 3)
%       .IW         - input weights (cell array)
%       .LW         - layer weights (cell array)
%       .b          - layer biases (cell array)
%       .layers     - layer definitions including activation functions

% load yaml file
tempNet = yamlread(yamlFile);

% Initialize net structure
uuvNet = struct();
uuvNet.name = 'Feed-Forward Neural Network';
uuvNet.numLayers = 3;
uuvNet.IW = cell(3,1);
uuvNet.LW = cell(3,3);
uuvNet.b = cell(3,1);
uuvNet.layers = cell(3,1);

% activation function
uuvNet.layers{1}.transferFcn = 'tansig';
uuvNet.layers{2}.transferFcn = 'tansig';
uuvNet.layers{3}.transferFcn = 'tansig';

% weight assignment
uuvNet.IW{1,1} = tempNet.weights.x1;
uuvNet.LW{2,1} = tempNet.weights.x2;
uuvNet.LW{3,2} = tempNet.weights.x3;

% bias assignment
uuvNet.b{1} = tempNet.offsets.x1';
uuvNet.b{2} = tempNet.offsets.x2';
uuvNet.b{3} = tempNet.offsets.x3';
end