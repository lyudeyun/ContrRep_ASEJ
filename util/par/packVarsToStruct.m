function s = packVarsToStruct(varargin)
% PACKVARSTOSTRUCT Packs name-value pairs into a struct.
%
%   s = packVarsToStruct('a', 1, 'b', 2) returns a struct:
%       s.a = 1;
%       s.b = 2;
%
%   This function is useful when you want to bundle multiple
%   named variables into a struct dynamically.
%
%   Inputs:
%       varargin - A list of name-value pairs (e.g., 'a', 1, 'b', 2)
%
%   Output:
%       s - A struct with fields named after the given variable names

    s = struct();
    for i = 1:2:length(varargin)
        key = varargin{i};
        val = varargin{i+1};
        s.(key) = val;
    end
end