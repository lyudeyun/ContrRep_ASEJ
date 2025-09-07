function mutateWeight(mdl, mut_mdl, mut_op, mut_mode)
% Given a simulink model and a set of mutation operators, mutateWeight can
% mutate the corresponding weights of this simulink model.
%
% Inputs:
%   mdl: simulink model
%   mut_mdl: the name of the simulink model to be mutated
%   mut_op: a set of mutation operators, including the mutation positions and mutator values
%   mut_mode: mutation mode: 'replace', 'add'
% Outputs:
%   mut_mdl: the mutated simulink model

%%% usage of find_system function
% nn_blocks = find_system('your model name/Feed-Forward Neural Network','LookUnderMasks','on');
% nn_blocks consists of the name of all the blocks

%%% usage of get_param function
% param_list = get_param('model/XXX_block','DialogParameters')
% param_list contains all of the numeric fields about XXX_block, then you
% can rerun this funtion to get the value of the numeric field you want
% get_param('model/XXX_block','numeric field 1')
%%% usage of set_param function
% set_param('model/XXX_block','numeric field 1', 'value')

% obtain the absolute path of the original model file
mdl_path = which([mdl, '.slx']);
% delete it if it exists.
if isfile([mut_mdl, '.slx'])
    delete([mut_mdl, '.slx']);
end
% copy original simulink model to initialize the mutated simulink model
copyfile(mdl_path, [mut_mdl, '.slx']);
load_system(fullfile([pwd, '/', mut_mdl, '.slx']));

for i = 1:size(mut_op,1)
    layer_idx = mut_op(i, 1);
    right_idx = mut_op(i, 2);
    left_idx = mut_op(i, 3);
    mutator_value = mut_op(i, 4);

    % obtain the name of current weight awaiting mutation. But currently, matlab
    % can only obtain all weights whose right endpoints are the same as that of current
    % weight to be mutated.
    if layer_idx == 1
        if contains(mut_mdl, 'WT') || contains(mut_mdl, 'ACC')
            % weight block name
            weight_str = [mut_mdl, '/Feed-Forward Neural Network/Layer ', num2str(layer_idx), '/IW{1,1}/IW{1,1}(', ...
                num2str(right_idx), ',:)'''];
        elseif contains(mut_mdl, 'AFC')
            weight_str = [mut_mdl, '/Air Fuel Control Model 1/Feed-Forward Neural Network/Layer ', num2str(layer_idx), '/IW{1,1}/IW{1,1}(', ...
                num2str(right_idx), ',:)'''];
        elseif contains(mut_mdl, 'SC')
            weight_str = [mut_mdl, '/Subsystem/Feed-Forward Neural Network/Layer ', num2str(layer_idx), '/IW{1,1}/IW{1,1}(', ...
                num2str(right_idx), ',:)'''];
        else
            error('The target blocks can not be found!');
        end
    else
        if contains(mut_mdl, 'WT') || contains(mut_mdl, 'ACC')
            weight_str = [mut_mdl, '/Feed-Forward Neural Network/Layer ', ...
                num2str(layer_idx), '/LW{', num2str(layer_idx), ',', num2str(layer_idx-1), '}/IW{', num2str(layer_idx), ',', num2str(layer_idx-1), ...
                '}(', num2str(right_idx), ',:)'''];
        elseif contains(mut_mdl, 'AFC')
            weight_str = [mut_mdl, '/Air Fuel Control Model 1/Feed-Forward Neural Network/Layer ', ...
                num2str(layer_idx), '/LW{', num2str(layer_idx), ',', num2str(layer_idx-1), '}/IW{', num2str(layer_idx), ',', num2str(layer_idx-1), ...
                '}(', num2str(right_idx), ',:)'''];
        elseif contains(mut_mdl, 'SC')
            weight_str = [mut_mdl, '/Subsystem/Feed-Forward Neural Network/Layer ', ...
                num2str(layer_idx), '/LW{', num2str(layer_idx), ',', num2str(layer_idx-1), '}/IW{', num2str(layer_idx), ',', num2str(layer_idx-1), ...
                '}(', num2str(right_idx), ',:)'''];
        else
            error('The target blocks can not be found!');
        end
    end

    % includes all weights whose right endpoints are the same as that of current
    % target weight.
    cur_weight_row_str = get_param(weight_str, 'Value');

    % split the str by semicolon ';'
    cur_weight_row_str = erase(cur_weight_row_str, '[');
    cur_weight_row_str = erase(cur_weight_row_str, ']');
    cur_weight_row_cell = strsplit(cur_weight_row_str, ';');

    % obtain the target weight
    target_weight_str = cur_weight_row_cell{1,left_idx};
    % we can specify the number of significant digits of vpa funciton. Since the target weight is
    % in a state of flux, there is no need to pursue a absolutely precious value.
    target_weight = vpa(target_weight_str, 100);
    % mutate the target weight
    if strcmp(mut_mode, 'add')
        target_weight = target_weight + mutator_value;
    elseif strcmp(mut_mode, 'replace')
        target_weight = mutator_value;
    end
    target_weight_str = char(vpa(target_weight, 100));
    
    % replace sps_weight_str to target_weight_str
    cur_weight_row_cell{1,left_idx} = target_weight_str;

    % assemble cur_weight_row_str
    new_weight_row_str = '';
    new_weight_row_str = strjoin(cur_weight_row_cell, ';');
    new_weight_row_str = ['[', new_weight_row_str, ']'];

    % set the weight in the model as the mutated weight
    set_param(weight_str, 'Value', num2str(new_weight_row_str));
end

% save the mutated model
save_system(mut_mdl);
close_system(mut_mdl);
end