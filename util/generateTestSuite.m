function TS = generateTestSuite(D, ts_size, ts_mode)
% generateTestSuite function returns a test suite based on a given dataset.
%
% Inputs:
%   D: the dataset built before
%   ts_size: the size of the test suite
%   ts_mode: the mode to generate the test suite, 'regular', 'allpass', 'all', 'average'
% Outputs:
%   TS: a set of external input signals of the system for test and
%   repair, including input signals, robustness values and the initial
%   fitness value of the generated test suite.

D_size = numel(D.tr_in_cell);

if ts_size > D_size
    error('The required size is greater than the size of the dataset!');
end

% initialize the test suite as a struct
TS.tr_in_cell = {};
TS.tr_rob_set = [];
TS.sn = 0;
TS.size = ts_size;

switch ts_mode
    case 'regular' 
        TS.tr_in_cell = D.tr_in_cell(1, 1:ts_size);
        TS.tr_rob_set = D.tr_rob_set(1:ts_size, 1);
        TS.sn = numel(find(TS.tr_rob_set > 0));
    case 'allpass'
        if sum(D.tr_rob_set > 0) < ts_size
            error("Insufficient input signals with positive robustness value in the dataset!");
        end
        TS.sn = ts_size;
        count = 0;
        for i = 1:D_size
            if D.tr_rob_set(i,1) > 0
                count = count + 1;
                TS.tr_in_cell{end+1} = D.tr_in_cell{1,i};
                TS.tr_rob_set = [TS.tr_rob_set; D.tr_rob_set(i,1)];
            end
            if count == ts_size
                break;
            end
        end
    case 'all'
        if ts_size ~= D_size
            error('The required size is different from the size of the dataset!');
        end
        TS.tr_in_cell = D.tr_in_cell;
        TS.tr_rob_set = D.tr_rob_set;
        TS.sn = D_size;     
    case 'average'
        if mod(ts_size, 2) ~= 0
            error("Check the size of the test suite!");
        end

        % % select ts_size/2 input signals with positive robustness value from dataset
        % pos_idx = dataset.tr_rob_set > 0;
        % test_suite.tr_in_cell = dataset.tr_in_cell(1,1:ts_);
        % pos_;
        % positive_numbers = positive_numbers(1:n);
        % % select ts_size/2 input signals with positive robustness value from dataset
        % negative_numbers = random_numbers(random_numbers < 0);
        % negative_numbers = negative_numbers(1:n);
        % 
        % negtive_numbers = ;
        
    otherwise
        error('Check the mode!');
end
end