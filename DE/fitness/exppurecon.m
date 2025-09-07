function [fitnessVal] = exppurecon(A, B)
% EXPPURECON Calculates the fitness value based on total robustness change.
%   fitnessVal = sum(B) - sum(A)
%
% Inputs
%   A - robustness list before repair
%   B - robustness list after applying an individual
%
% Outputs
%   fitnessVal - fitness value representing the total robustness improvement

fitnessVal = sum(B) - sum(A);
end