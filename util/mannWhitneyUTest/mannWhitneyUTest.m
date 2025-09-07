function [matrixP, matrixH, cellStats] = mannWhitneyUTest(data)
% mannWhitneyUTest function performs pairwise comparisons between groups
% using the Mann-Whitney U test to assess whether two independent samples
% (obtained from different approaches) come from the same distribution.
%
% Inputs:
%   data - A matrix where each column represents the data obtained from a specific approach
%
% Outputs:
%   matrixP   - A symmetric matrix storing p-values for each app pair (appNum x appNum)
%   matrixH   - A symmetric matrix storing test decisions (0 = fail to reject H0, 1 = reject H0)
%   cellStats - A cell array storing test statistics for each app pair

% Determine the number of approaches
appNum = size(data, 2);

% Initialize matrices to store results
matrixP = zeros(appNum, appNum);  % p-values
matrixH = zeros(appNum, appNum);  % hypothesis test results
cellStats = cell(appNum, appNum); % test statistics

% Perform Mann-Whitney U test (Wilcoxon rank-sum test) for each app pair
for i = 1:appNum
    for j = i:appNum
        [p, h, stats] = ranksum(data(:, i), data(:, j));  % Mann-Whitney U Test
        
        % Store results in symmetric matrices
        matrixP(i, j) = p;
        matrixP(j, i) = p;
        matrixH(i, j) = h;
        matrixH(j, i) = h;
        cellStats{i, j} = stats;
        cellStats{j, i} = stats;
    end
end
end