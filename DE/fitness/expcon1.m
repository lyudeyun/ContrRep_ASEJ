function [fitnessVal] = expcon1(A, B)
% EXPCON1 Calculates the fitness value based on the following formula:
% 10K * (#Repaired - #Broken) + 
% sum of ΔRob for Improve_negative (Improve_negative_negative and Improve_negative_positive) + 
% sum of ΔRob for Worsen (Worsen_positive_positive, Worsen_positive_negative and Worsen_negative_negative)
%
% This function supports two modes:
%   - Normal mode: when all robustness values in B are numeric.
%   - Estimation mode: NaNs in B are optimistically treated as B(i) = 100
%
% Inputs:
%   A - robustness list before repair
%   B - robustness list after applying an individual
%
% Outputs:
%   fitnessVal - fitness value

if any(isnan(B))
    % Estimation mode
    % Replace NaNs in B with 100 to represent optimistic robustness estimation
    estB = B;
    estB(isnan(B)) = 100;
    deltaRob = estB - A;
    % Mask out Improve_positive_positive cases
    mask = (estB > A) & (A > 0) & (estB > 0);
    fitnessVal = 10000 * (sum(B > 0 | isnan(B)) - sum(A > 0)) + sum(deltaRob(~mask));
else
    % Normal mode
    % we do not consider the case Improve_positive_positive
    mask = (B > A) & (A > 0) & (B > 0);
    deltaRob = (B - A) .* ~mask;
    fitnessVal = 10000 * (sum(B > 0) - sum(A > 0)) + sum(deltaRob);
end
