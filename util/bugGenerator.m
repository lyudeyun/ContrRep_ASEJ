function bug_list = bugGenerator(bug_lb, bug_ub, dist_mode, K, weight_list)
% bugGenerator function returns K bugs according to the requirements.
%
% Inputs:
%   bug_lb: lower bound
%   bug_ub: upper bound
%   dist_mode: generate the bug values that conform to a certain distribution, 'random', 'natural', 'gaussian'
%   K: the dim of current mutation operator, i.e., the number of weights to be mutated
%   weight_list: the list of weight values for reference when dist_mode is 'natural'
% Outputs:
%   bug_list: the generated bugs

if strcmp(dist_mode, 'random')
    bug_list = (bug_ub - bug_lb)*rand(K,1) + bug_lb;
elseif strcmp(dist_mode, 'natural')
    % estimate the probability density function using kernel density estimation
    pd = fitdist(weight_list, 'Kernel');
    bug_list = random(pd, [K,1]);
elseif strcmp(dist_mode, 'normal')
    gau_sample = randn(K, 1);
    bug_list = lb + (ub - lb) * cdf('Normal', gau_sample, 0, 1);
else
    error("Check the mut_conf.dist_mode!");
end
% constrain the range of the bug_list
bug_list(bug_list < bug_lb) = bug_lb;
bug_list(bug_list > bug_ub) = bug_ub;
end