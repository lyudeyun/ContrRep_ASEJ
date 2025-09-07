function mutatedWeight = resetWeight(net, mut_op, mut_mode)
% Given a neural network controller, resetWeight function returns the weight after mutation. (for RQ1)
%
% Inputs:
%   net: neural network controller
%   mut_op: a set of mutation operators {layer index, right index, left index and mutator value}
%   mut_mode: mutation mode
% Outputs:
%   mutatedWeight: the weight after mutation

mutatedWeight = cell(1, net.numLayers);

for li = 1: net.numLayers
    if li == 1
        mutatedWeight{1,li} = net.IW{1,1};
    else
        mutatedWeight{1,li} = net.LW{li,li-1};
    end
end

% reproduce the weight after mutation
for mi = 1:size(mut_op, 1)
    if strcmp(mut_mode, 'replace')
        mutatedWeight{1, mut_op(mi,1)}(mut_op(mi,2), mut_op(mi,3)) = mut_op(mi,4);
    elseif strcmp(mut_mode, 'add')
        mutatedWeight{1, mut_op(mi,1)}(mut_op(mi,2), mut_op(mi,3)) = mutatedWeight{1, mut_op(mi,1)}(mut_op(mi,2), mut_op(mi,3)) + mut_op(mi,4);
    else
        error('Check the mutation mode!');
    end
end
end