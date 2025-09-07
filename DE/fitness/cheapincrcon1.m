function [fitnessVal] = cheapincrcon1(A, B)
% CHEAPINCRCON1 Calculates the fitness value based on the following formula:
% 10K * (#Repaired - #Broken) + 
% sum of ΔRob for Improve_negative (Improve_negative_negative and Improve_negative_positive) +
% sum of ΔRob for Worsen (Worsen_negative_negative, Worsen_positive_positive, and Worsen_positive_negative)
%
% Similar to EXPCON1, but only finite values in B are considered in the fitness calculation.
% For Inf and -Inf values in B, we assume they retain the same values as in A.
%
% Inputs:
%   A - robustness list before repair
%   B - robustness list after applying an individual
%
% Outputs:
%   fitnessVal - fitness value

roi = B ~= -Inf & B ~= Inf;
% we do not consider the case Improve_positive_positive
mask = (B > A) & (A > 0) & (B > 0);
newRoi = ~mask & roi;
diff = B - A;
fitnessVal = sum(diff(newRoi)) + 10000 * (sum(B > 0) - sum(A > 0));
end




