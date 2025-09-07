function [fitnessVal] = cheapincrdis(A, B)
% CHEAPINCRDIS Calculates the fitness value based on the following formula:
% #Repaired - #Broken
% 
% Inputs:
%   A - robustness list before repair
%   B - robustness list after applying an individual
%
% Outputs:
%   fitnessVal - fitness value

fitnessVal = sum(B > 0) - sum(A > 0);


