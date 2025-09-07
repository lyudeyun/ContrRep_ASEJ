function unpackStructToCaller(s)
% UNPACKSTRUCTTOCALLER unpacks fields of struct `s` to variables in the caller workspace.
%
% Example:
%   s.a = 1; s.b = 2;
%   unpackStructToCaller(s);
%   % Now `a` and `b` are available in your workspace.

    if ~isstruct(s)
        error('Input must be a struct.');
    end

    fields = fieldnames(s);
    for i = 1:numel(fields)
        assignin('caller', fields{i}, s.(fields{i}));
    end
end