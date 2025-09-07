function [w] = selectScalingFactor(trajLen, frameNum, Ts, state, conf)

if state == 1
    % equal weights
    w = ones(frameNum, 1);
elseif state == 0 && conf.window == 0
    w = trajLen * ones(frameNum, 1)/frameNum;
elseif state == 0 && conf.window == 1
    % hamming window  weight the weight2OutBinary (just a heuristic idea)
    init_w = hamming(frameNum * 2);
    scale = trajLen/sum(init_w(1:frameNum, 1));
    w = scale * init_w;
elseif state == 0 && conf.window == 2
    if conf.win_sz <= frameNum * Ts
        % taus >= fixed_win
        init_w = zeros(frameNum, 1);
        start_idx = frameNum - conf.win_sz/Ts + 1;
        init_w(start_idx:end, 1) = 1;
        scale = trajLen/(conf.win_sz/Ts);
        w = scale * init_w;
    else
        % taus < fixed_win
        w = trajLen * ones(frameNum, 1)/frameNum;
    end
    %
elseif state == 0 && conf.window == 3
    % for i=10:-1:1 end
    init_w = zeros(frameNum, 1);
    start_idx = this.monitorRob(diagInfo);
    win_sz = frameNum - start_idx + 1;
    init_w(start_idx:end, 1) = 1;
    scale = trajLen/win_sz;
    w = scale * init_w;
end

end


