function TS = sortTestSuite(TS)
% SORTTESTSUITE Sorts test cases by robustness in descending order.
%
% Inputs
%   TS: test suite before sorting, with field 'testCases'
%
% Outputs
%   TS: test suite after sorting, with 'testCases' sorted by 'rob' descending

testCases = TS.testCases;

% Sort test cases by 'rob' in descending order
[~, idx] = sort([testCases.rob], 'descend');

% Reorder test cases
TS.testCases = testCases(idx);
end