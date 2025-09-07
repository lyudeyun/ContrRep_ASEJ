function top50_weight = selectTop50Weight(weight2Out, li_l, li_r, sel_mode)
% selectTop50Weight function returns the neural weight whose forward
% impact is greater than the average.
%
% Inputs:
%   weight2Out: the forward impact of each weight during a simulation.
%   li_l: li_l == 1, consider input weights; li_l == 2: do not consider input weights.
%   li_r: li_r == this.layer_num + 1, consider output weights; li_r ==
%   this.layer_num, do not consider output weights.
%   sel_mode: 'average': forward impact > average forward impact; 'median'
% Outputs:
%   top50_weight: weight position

weight_candidate = [];

weight2OutSum = weight2Out{1, 1};
for frame_i = 1:numel(weight2Out)
    for li = 1: numel(weight2OutSum)
        if frame_i == 1
            weight2OutSum{1, li} = abs(weight2OutSum{1, li});
        else
            weight2OutSum{1,li} = weight2OutSum{1,li} + abs(weight2Out{1, frame_i}{1, li});
        end
    end
end

weight_list = [];
% analyze the weights between layer li_l and li_r
for m = li_l:li_r
    [rows, cols] = size(weight2OutSum{1, m});
    for r = 1:rows
        for c = 1:cols
            % collect forward impact of each weight and its position
            weight_list = [weight_list; [m, r, c, weight2OutSum{1, m}(r, c)]];
        end
    end
end

if strcmp(sel_mode, 'average')

    avg_fi = mean(weight_list(:, 4));
    [sorted_weight_list] = sortrows(weight_list, 4, 'descend');
    indices = sorted_weight_list(:,4) > avg_fi;
    top50_weight = sorted_weight_list(indices, :);

elseif strcmp(sel_mode, 'median')
    mid_fi = median(weight_list(:, 4));
    [sorted_weight_list] = sortrows(weight_list, 4, 'descend');
    indices = sorted_weight_list(:,4) > mid_fi;
    top50_weight = sorted_weight_list(indices, :);
else
    error('Check your topk_mode!');
end

end