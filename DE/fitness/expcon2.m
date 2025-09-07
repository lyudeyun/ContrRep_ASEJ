function [fitnessVal] = expcon2(A, B)
% EXPCON2 Calculates the fitness value based on the following formula:
% 10K * (#Repaired - #Broken) +
% sum of ΔRob for Improve_negative (Improve_negative_positive and Improve_negative_negative) +
% sum of ΔRob for Worsen_positive_negative and Worsen_negative_negative
%
% Compared to EXPCON1, EXPCON2 does not consider the case Worsen_positive_positive.
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
    % Mask out Improve_positive_positive and Worsen_positive_positive
    mask = (A > 0) & (estB > 0);
    fitnessVal = 10000 * (sum(B > 0 | isnan(B)) - sum(A > 0)) + sum(deltaRob(~mask));
else
    % Normal mode
    % Exclude Improve_positive_positive and Worsen_positive_positive
    mask = (A > 0) & (B > 0);  
    deltaRob = (B - A) .* ~mask;
    fitnessVal = 10000 * (sum(B > 0) - sum(A > 0)) + sum(deltaRob);
end
end



 
   
