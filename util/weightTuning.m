function weightTuning(mdl, weight, weight_patch, sps_weight_info, mdl_new)
% Given a simulink model and weight patch, weightTuning function can
% modify the neural weights of a simulink model directly.
%
% Inputs:
%   mdl: simulink model
%   weight: neural weights
%   weight_patch: weight patch
%   sps_weight_info: includes suspiciousness score of a suspicious weight, weight value, layer_idx, right_endpoint_idx, left_endpoint_idx
% Outputs:
%   mdl_new: simulink model with applied weight patch


%%% usage of find_system function
% find_system function aims to list out the names of sub blocks under your target block.
% nn_blocks = find_system('your mdl name/Feed-Forward Neural Network','LookUnderMasks','on');
% nn_blocks consists of the name of all the blocks

%%% usage of get_param function
% param_list = get_param('model/XXX_block','DialogParameters')
% or param_list = get_param('model/XXX_block','ObjectParameters')
% param_list contains all of the numeric fields about XXX_block, then you
% can rerun this funtion to get the value of the numeric field you want
% get_param('model/XXX_block','numeric field 1')
% for example, get_param('model/XXX_block','Value'), 'Value' is a numeric field.

%%% usage of set_param function
% set_param('model/XXX_block','numeric field 1', 'value')
% for example, set_param('model/XXX_block','Value', '123') 

% copy original simulink model as a new model mdl_new 
copyfile([mdl, '.slx'], [mdl_new, '.slx']);
% load new model
load_system(mdl_new);

[row, ~] = size(sps_weight_info);

for i = 1:row
    layer_idx = sps_weight_info(i, 3);
    right_idx = sps_weight_info(i, 4);
    left_idx = sps_weight_info(i, 5);
    % obtain the name of current suspicious weight. But currently, matlab
    % can only obtain weight by row. 
    if layer_idx == 1
        % weight block name
        weight_str = [mdl_new, '/Feed-Forward Neural Network/Layer ', num2str(layer_idx), '/IW{1,1}/IW{1,1}(', ...
            num2str(right_idx), ',:)'''];
    else
        weight_str = [mdl_new, '/Feed-Forward Neural Network/Layer ', ...
            num2str(layer_idx), '/LW{', num2str(layer_idx), ',', num2str(layer_idx-1), '}/IW{', num2str(layer_idx), ',', num2str(layer_idx-1), ...
            '}(', num2str(right_idx), ',:)'''];
    end
    
    % includes all weights whose right endpoints are the same as that of current
    % suspicious weight. 
    cur_weight_row_str = get_param(weight_str, 'Value');

    if str2num(cur_weight_row_str) ~= weight{1, layer_idx}(right_idx, :)'
        error('current weight row is not equal to the weight row stored in weight cell!');
    end
    
    % split the str by semicolon ';'
    cur_weight_row_str = erase(cur_weight_row_str, '[');
    cur_weight_row_str = erase(cur_weight_row_str, ']');
    cur_weight_row_cell = strsplit(cur_weight_row_str, ';');
    
    % obtain the target weight
    sps_weight_str = cur_weight_row_cell{1,left_idx};
    % we can specify the number of significant digits of vpa funciton. Since sps_weight is
    % in a state of flux, there is no need to pursue a absolutely precious value.
    sps_weight = vpa(sps_weight_str, 100);
    % apply the weight patch
    target_weight = sps_weight + weight_patch(1,i);
    % sym to str 
    target_weight_str = char(target_weight);
    % replace sps_weight_str to target_weight_str
    cur_weight_row_cell{1,left_idx} = target_weight_str;

    % assemble cur_weight_row_str
    new_weight_row_str = '';
    new_weight_row_str = strjoin(cur_weight_row_cell, ';');
    new_weight_row_str = ['[', new_weight_row_str, ']'];

   % apply the target weight
    set_param(weight_str, 'Value', num2str(new_weight_row_str));
end

% save new model
save_system(mdl_new, [],'OverwriteIfChangedOnDisk',true);
end

