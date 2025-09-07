function [a12Matrix, a12Labels] = computeA12Matrix(data)
% computeA12Matrix function computes the Vargha-Delaney A12 effect size 
% between the data obtained from different approaches and assigns qualitative labels.
%
% Inputs:
%   data - A matrix where each column represents a different approach
%
% Outputs:
%   a12Matrix  - A symmetric matrix storing A12 effect size values
%   a12Labels  - A matrix storing qualitative descriptions of A12 values

% Determine the number of approaches
appNum = size(data, 2);

% Initialize the A12 effect size matrix
a12Matrix = zeros(appNum, appNum);

% Compute A12 effect size
for i = 1:appNum
    for j = 1:appNum
        a12Matrix(i, j) = a12(data(:, i), data(:, j));
    end
end

% Convert to string matrix for storing qualitative labels
a12Labels = strings(appNum, appNum);

% Define A12 effect size categories
largeBad = (a12Matrix >= 0 & a12Matrix <= 0.286);
mediumBad = (a12Matrix > 0.286 & a12Matrix <= 0.362);
smallBad = (a12Matrix > 0.362 & a12Matrix <= 0.444);
negligibleBad = (a12Matrix > 0.444 & a12Matrix < 0.5);
equivalent = (a12Matrix == 0.5);
negligibleGood = (a12Matrix > 0.5 & a12Matrix < 0.556);
smallGood = (a12Matrix >= 0.556 & a12Matrix < 0.638);
mediumGood = (a12Matrix >= 0.638 & a12Matrix < 0.714);
largeGood = (a12Matrix >= 0.714 & a12Matrix <= 1);

% Assign qualitative labels
a12Labels(largeBad) = "large_bad";
a12Labels(mediumBad) = "medium_bad";
a12Labels(smallBad) = "small_bad";
a12Labels(negligibleBad) = "negligible_bad";
a12Labels(equivalent) = "equivalent";
a12Labels(negligibleGood) = "negligible_good";
a12Labels(smallGood) = "small_good";
a12Labels(mediumGood) = "medium_good";
a12Labels(largeGood) = "large_good";
end