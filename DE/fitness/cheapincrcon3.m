function [fitnessVal] = cheapincrcon3(A, B)
% CHEAPINCRCON1 Calculates the fitness value based on the following formula:
% 10K * (#Repaired - #Broken) + 
% sum of ΔRob for Improve_negative_negative + 
% sum of ΔRob for Worsen_negative_negative
%
% Similar to CHEAPINCRCON1, only finite values in B are considered in the fitness calculation.
% For Inf and -Inf values in B, we assume they retain the same values as in A.
%
% Inputs:
%   A - robustness list before repair
%   B - robustness list after applying an individual
%
% Outputs:
%   fitnessVal - fitness value

% we only conside the case Improve_negative_negative and Worsen_negative_negative
roi = (A < 0) & (A ~= -Inf) & (B < 0) & (B ~= -Inf);
diff = B - A;
fitnessVal = sum(diff(roi)) + 10000 * (sum(B > 0) - sum(A > 0));
end




