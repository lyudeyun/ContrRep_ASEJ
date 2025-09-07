function assignStructToBase(s)
    % Assign each field in struct s to base workspace
    fns = fieldnames(s);
    for i = 1:numel(fns)
        assignin('base', fns{i}, s.(fns{i}));
    end
end