function [weight, ori_weight, sps_weight] = weightSync(net, mut_mode, mut_op)
% Given a neural network controller, weightSync function updates the
% all the weights and the suspicious weights mutated by the mutation operator
%
% Inputs:
%   net: neural network controller
%   mut_mode: mutation mode
%   mut_op: a mutation operator, each row represents a weight bug
% Outputs:
%   weight: the updated weights
%   ori_weight: 
%   sps_weight: suspicious weights

% load the weights from net
weight = cell(1, net.numLayers);

for li = 1: net.numLayers
    if li == 1
        weight{1,li} = net.IW{1,1};
    else
        weight{1,li} = net.LW{li,li-1};
    end
end

ori_weight = mut_op;
sps_weight = mut_op;

if ~isempty(mut_op)
    for bi = 1:size(mut_op, 1)
        li = mut_op(bi,1);
        i = mut_op(bi,2);
        j = mut_op(bi,3);
        if strcmp(mut_mode, 'plus')
            ori_weight(bi,4) = weight{1,li}(i,j);
            weight{1,li}(i,j) = weight{1,li}(i,j) + mut_op(bi,4);
            sps_weight(bi,4) = weight{1,li}(i,j);
        elseif strcmp(mut_mode, 'replace')
            ori_weight(bi,4) = weight{1,li}(i,j); 
            weight{1,li}(i,j) = mut_op(bi,4);
        end
    end
end
end