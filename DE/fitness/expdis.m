function [fitnessVal] = expdis(A, B)
% EXPDIS Calculates the fitness value as the difference between the number of
% repaired and broken test cases after applying an individual.
%
% This function supports two modes:
%   - Normal mode: when all robustness values in B are numeric.
%   - Estimation mode: when B contains NaNs, indicating unknown results.
%     In this case, NaNs are optimistically treated as potentially repaired,
%     and the returned fitnessVal serves as an upper bound.
%
% Inputs:
%   A - robustness list before repair (N × 1 double)
%   B - robustness list after applying an individual (N × 1 double), may include NaNs
%
% Output:
%   fitnessVal - estimated or exact fitness value (#Repaired - #Broken)

if any(isnan(B))
    % Estimation mode: fitnessVal is an upper bound assuming all NaNs may be positive
    fitnessVal = sum(B > 0 | isnan(B)) - sum(A > 0);  
else
    % Normal mode
    fitnessVal = sum(B > 0) - sum(A > 0);
end

