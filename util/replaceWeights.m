function replaceWeights(oriModelName, oriWeights, altWeights, spsWeights, newModelName)
% REPLACEWEIGHTS Replaces specific neural weights in a Simulink model.
%
% Inputs:
%   oriModelName - Name of the original Simulink model (without '.slx')
%   oriWeights   - Original weights stored as a cell array per layer
%   altWeights    - New weight values to be substituted (1 × numSpsWeights)
%   spsWeights    - [layerIdx, rowIdx, colIdx, oriVal, spsScore] info for each suspicious weight
%   newModelName  - Name of the new model to be created (without '.slx')
%
% This function replaces weights in a model while preserving original weight shape and format.

% Copy model
modelPath = which([oriModelName, '.slx']);
copyfile(modelPath, [newModelName, '.slx']);
load_system(fullfile(pwd, [newModelName, '.slx']));

spsWNum = size(spsWeights, 1);

for wi = 1:spsWNum
    layerIdx = spsWeights(wi, 1);
    rowIdx   = spsWeights(wi, 2);
    colIdx   = spsWeights(wi, 3);

    % Construct Simulink parameter path
    if layerIdx == 1
        if contains(oriModelName, 'WT') || contains(oriModelName, 'ACC')
            weightParamPath = [newModelName, '/Feed-Forward Neural Network/Layer ', num2str(layerIdx), ...
                '/IW{1,1}/IW{1,1}(', num2str(rowIdx), ',:)'''];
        elseif contains(oriModelName, 'AFC')
            weightParamPath = [newModelName, '/Air Fuel Control Model 1/Feed-Forward Neural Network/Layer ', ...
                num2str(layerIdx), '/IW{1,1}/IW{1,1}(', num2str(rowIdx), ',:)'''];
        elseif contains(oriModelName, 'SC')
            weightParamPath = [newModelName, '/Subsystem/Feed-Forward Neural Network/Layer ', ...
                num2str(layerIdx), '/IW{1,1}/IW{1,1}(', num2str(rowIdx), ',:)'''];
        else
            error('Target block not found in layer 1.');
        end
    else
        if contains(oriModelName, 'WT') || contains(oriModelName, 'ACC')
            weightParamPath = [newModelName, '/Feed-Forward Neural Network/Layer ', num2str(layerIdx), ...
                '/LW{', num2str(layerIdx), ',', num2str(layerIdx-1), '}/IW{', num2str(layerIdx), ',', ...
                num2str(layerIdx-1), '}(', num2str(rowIdx), ',:)'''];
        elseif contains(oriModelName, 'AFC')
            weightParamPath = [newModelName, '/Air Fuel Control Model 1/Feed-Forward Neural Network/Layer ', ...
                num2str(layerIdx), '/LW{', num2str(layerIdx), ',', num2str(layerIdx-1), '}/IW{', ...
                num2str(layerIdx), ',', num2str(layerIdx-1), '}(', num2str(rowIdx), ',:)'''];
        elseif contains(oriModelName, 'SC')
            weightParamPath = [newModelName, '/Subsystem/Feed-Forward Neural Network/Layer ', ...
                num2str(layerIdx), '/LW{', num2str(layerIdx), ',', num2str(layerIdx-1), '}/IW{', ...
                num2str(layerIdx), ',', num2str(layerIdx-1), '}(', num2str(rowIdx), ',:)'''];
        else
            error('Target block not found in hidden layers.');
        end
    end

    % Get and parse original weight string
    curWeightStr = get_param(weightParamPath, 'Value');

    % Retrieve the entire weight vector for the current neuron from the model
    curWeightVal = str2num(curWeightStr); %#ok<ST2NM>
    oriWeightVal = oriWeights{1, layerIdx}(rowIdx, colIdx);

    if abs(curWeightVal(colIdx) - oriWeightVal) > 1e-10
        error('Mismatch at [Layer %d, Row %d, Col %d]: model = %.16f, expected = %.16f', ...
            layerIdx, rowIdx, colIdx, curWeightVal(colIdx), oriWeightVal);
    end

    % Split the str by semicolon ';'
    strippedStr = erase(erase(curWeightStr, '['), ']');
    curWeightCell = strsplit(strippedStr, ';');

    % Replace the specific column value with new weight (16-digit precision)
    curWeightCell{1, colIdx} = sprintf('%.16g', altWeights(1, wi));

    % Reconstruct and set new weight row string
    updatedWeightStr = ['[', strjoin(curWeightCell, ';'), ']'];
    set_param(weightParamPath, 'Value', updatedWeightStr);
end

% Save and close the updated model
save_system(newModelName, [], 'OverwriteIfChangedOnDisk', true);
close_system(newModelName, 0);
end