function [fitnessVal] = expcon3(A, B)
% EXPCON3 Calculates the fitness value based on the following formula:
% 10K * (#Repaired - #Broken) +
% sum of ΔRob for Improve_negative_negative +
% sum of ΔRob for Worsen_negative_negative
%
% Compared to EXPCON2, EXPCON3 does not consider Improve_negative_positive
% and Worsen_positive_negative, as they are already reflected in (#Repaired - #Broken).
%
% In estimation mode (B contains NaNs):
%   - NaNs in B are treated optimistically as B = 100
%   - #Repaired includes (B > 0) or isnan(B)
%
% Inputs:
%   A - robustness list before repair
%   B - robustness list after applying an individual
%
% Outputs:
%   fitnessVal - fitness value

if any(isnan(B))
    % Estimation mode
    estB = B;
    estB(isnan(B)) = 100;
    deltaRob = estB - A;
    % Only consider Improve_negative_negative and Worsen_negative_negative
    roi = (A < 0) & (estB < 0);
    fitnessVal = 10000 * (sum(B > 0 | isnan(B)) - sum(A > 0)) + sum(deltaRob(roi));
else
    % Normal mode
    % Only only conside the case Improve_negative_negative and Worsen_negative_negative
    roi = (A < 0) & (B < 0);
    fitnessVal = 10000 * (sum(B > 0) - sum(A > 0)) + sum((B - A) .* roi);
end