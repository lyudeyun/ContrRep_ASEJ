function [uuvNet] = uuvWeightReplace(oriYamlFile, newYamlFile, altWeights, spsWeights)
% UUVWEIGHTREPLACE replaces specific weights in a UUV network YAML file.
%
% Inputs
%   oriYamlFile: path to the original YAML file of nn controller
%   newYamlFile: path to save the updated YAML file
%   spsWeights: [li, i, j, val]
%
% Output
%   uuvNet: struct representing the updated UUV network

spsWNum = size(spsWeights,1);
tempSpsWeights = num2cell(spsWeights);

% layer field mapping
layerFields = {'x1', 'x2', 'x3'};

% load original nn controller in YAML
if ~endsWith(oriYamlFile, '.yml')
    oriYamlFile = [oriYamlFile, '.yml'];
end


oriYamlPath = which(oriYamlFile);
if isempty(oriYamlPath)
    error('File not found: %s', oriYamlFile);
else
    uuvNet = yamlread(oriYamlPath);
end

for wi = 1:spsWNum
    [li,i,j] = tempSpsWeights{wi,1:3}; 
    uuvNet.weights.(layerFields{li})(i,j) = altWeights(wi);
end

% save modified nn controller to YAML
if ~endsWith(newYamlFile, '.yml')
    newYamlFile = [newYamlFile, '.yml'];
end
yamlwrite(uuvNet, newYamlFile);
end