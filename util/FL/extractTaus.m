function [taus, validVioIdx] = extractTaus(bm, mdl, T, Ts, Br, in_sig, phi_str)

trajLen = T/Ts + 1;

if strcmp(bm, 'ACC')
    activeIntervals = [0,50];
elseif strcmp(bm, 'AFC') && contains(phi_str, 'alw_[0,')
    activeIntervals = [0,30];
elseif strcmp(bm, 'AFC') && contains(phi_str, 'alw_[10,')
    activeIntervals = [10,30];
elseif strcmp(bm, 'WT')
    activeIntervals = [4,4.9; 9,9.9; 14,14.9];
elseif strcmp(bm, 'SC')
    activeIntervals = [30,35];
else
    error('Unknown benchmark or unsupported phi_str!');
end

activeTMask = zeros(1, trajLen);
vioTMask = zeros(1, trajLen);


for acti = 1: size(activeIntervals,1)
    activeI = activeIntervals(acti,:);
    activePos = activeI./Ts;
    activeTMask(1, activePos(1)+1:activePos(2)+1) = 1;
end

switch bm
    case 'ACC'
        dRel = sigMatch(Br, "d_rel") - 1.4 * sigMatch(Br, "v_ego");
        vEgo = sigMatch(Br, "v_ego");

        if strcmp(phi_str, 'alw_[0,50]((d_rel[t] - 1.4 * v_ego[t] >= 10) and v_ego[t] <= 30.1)')

            vioIdx = dRel < 10 | vEgo > 30.1;
            vioTMask(1, vioIdx) = 1;

        elseif strcmp(phi_str, 'alw_[0,50]((d_rel[t] - 1.4 * v_ego[t] >= 10) and (d_rel[t] - 1.4 * v_ego[t] <= 50) and (v_ego[t] >= 20) and (v_ego[t] <= 30))')

            leftVioIdx = find(dRel < 10 | dRel > 50);
            rightVioIdx = find(vEgo < 20 | vEgo > 30);
            vioIdx = union(leftVioIdx, rightVioIdx);
            vioTMask(1, vioIdx) = 1;
        
        elseif strcmp(phi_str, 'alw_[0,50]((d_rel[t] - 1.4 * v_ego[t] >= 10) and (v_ego[t] >= 20) and (v_ego[t] <= 30))')
            leftVioIdx = find(dRel < 10);
            rightVioIdx = find(vEgo < 20 | vEgo > 30);
            vioIdx = union(leftVioIdx, rightVioIdx);
            vioTMask(1, vioIdx) = 1;

        elseif strcmp(phi_str, 'alw_[0,50]((d_rel[t] - 1.4 * v_ego[t] >= 10) and (v_ego[t] >= 10) and (v_ego[t] <= 30))')
            leftVioIdx = find(dRel < 10);
            rightVioIdx = find(vEgo < 10 | vEgo > 30);
            vioIdx = union(leftVioIdx, rightVioIdx);
            vioTMask(1, vioIdx) = 1;

        elseif strcmp(phi_str, 'alw_[0,45]((d_rel[t] - 1.4 * v_ego[t] <= 12) => ev_[0,5](d_rel[t] - 1.4 * v_ego[t] > 12))') || ...
                strcmp(phi_str, 'alw_[0,45](not(d_rel[t] - 1.4 * v_ego[t] <= 12) or ev_[0,5](d_rel[t] - 1.4 * v_ego[t] > 12))')
            for i = 1:451
                if dRel(1,i) <= 12
                    deadlineI = i+50;
                    windowedDRel = dRel(1, i:deadlineI);
                    if ~any(windowedDRel > 12)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
            end
        elseif strcmp(phi_str, 'alw_[0,45](not(d_rel[t] - 1.4 * v_ego[t] <= 15 or v_ego[t] <= 15) or ev_[0,5](d_rel[t] - 1.4 * v_ego[t] > 15 and v_ego[t] > 15))')
            for i = 1:451
                if dRel(1,i) <= 15
                    deadlineI = i+50;
                    windowedDRel = dRel(1, i:deadlineI);
                    if ~any(windowedDRel > 15)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
                if vEgo(1,i) <= 15
                    deadlineI = i+50;
                    windowedVEgo = vEgo(1, i:deadlineI);
                    if ~any(windowedVEgo > 15)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
            end
        elseif strcmp(phi_str, 'alw_[0,45](not(d_rel[t] - 1.4 * v_ego[t] <= 12 or v_ego[t] <= 12) or ev_[0,5](d_rel[t] - 1.4 * v_ego[t] > 12 and v_ego[t] > 12))')
            for i = 1:451
                if dRel(1,i) <= 12
                    deadlineI = i+50;
                    windowedDRel = dRel(1, i:deadlineI);
                    if ~any(windowedDRel > 12)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
                if vEgo(1,i) <= 12
                    deadlineI = i+50;
                    windowedVEgo = vEgo(1, i:deadlineI);
                    if ~any(windowedVEgo > 12)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
            end
        elseif strcmp(phi_str, 'alw_[0,47](not(d_rel[t] - 1.4 * v_ego[t] <= 15 or v_ego[t] <= 15) or ev_[0,3](d_rel[t] - 1.4 * v_ego[t] > 15 and v_ego[t] > 15))')
            for i = 1:471
                if dRel(1,i) <= 15
                    deadlineI = i+30;
                    windowedDRel = dRel(1, i:deadlineI);
                    if ~any(windowedDRel > 15)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
                if vEgo(1,i) <= 15
                    deadlineI = i+30;
                    windowedVEgo = vEgo(1, i:deadlineI);
                    if ~any(windowedVEgo > 15)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
            end
        else 
            error('Unsupported phi_str of ACC!');
        end

    case 'AFC'
        af = sigMatch(Br, "AF");
        mu = abs(af - 14.7)/14.7;
        if strcmp(phi_str, 'alw_[0,30](AF[t] < 1.15*14.7 and AF[t] > 0.85*14.7)')
            vioTMask(mu >= 0.15) = 1;
        elseif strcmp(phi_str, 'alw_[0,30](AF[t] < 1.2*14.7 and AF[t] > 0.8*14.7)')
            vioTMask(mu >= 0.2) = 1;
        elseif strcmp(phi_str, 'alw_[0,29.7](not(AF[t] >= 1.1*14.7 or AF[t] <= 0.9*14.7) or ev_[0,0.3](AF[t] < 1.1*14.7 and AF[t] > 0.9*14.7))')
            for i = 1:299
                if af(1,i) >= 1.1*14.7 || af(1,i) <= 0.9*14.7
                    deadlineI = i + 2;
                    windowedAF = af(1, i:deadlineI);
                    if ~any(windowedAF < 1.1*14.7 & windowedAF > 0.9*14.7)
                        vioTMask(1, deadlineI) = 1;
                    end
                end
            end
        else
            error('Unsupported phi_str of AFC!');
        end

    case 'SC'
        pressure = sigMatch(Br, "pressure");
        vioTMask(pressure < 87 | pressure > 87.5) = 1;

    case 'WT'
        h_error = abs(sigMatch(Br, "h_error"));
        vioTMask(h_error > 0.86) = 1;
    otherwise
end

validVioTMask = vioTMask .* activeTMask;

if ~ismember(1,validVioTMask)
    sysTime = datevec(datestr(now));
    % record current bug
    logName = 'diagBugLog';
    for i = 1:numel(sysTime)
        logName = strcat(logName, '_', num2str(sysTime(1,i)));
    end
    logName = [logName, '.mat'];
    save(logName, 'Br', 'mdl', 'in_sig');
    disp('robustness > 0');
    taus = T;
    validVioIdx = trajLen;
    return;
end
validVioIdx = find(validVioTMask == 1);
taus = (validVioIdx(1) - 1) * Ts;
end


% localize tau_s using online monitoring. Thank you, Zhenya
% tau = 0;
% time_ = Br.P.traj{1}.time;
% time = round(time_, 2);
% sig_list = cellstr(split(this.sig_str, ","));
% X = sigMatch(Br, sig_list);
% trace = [time; X];
% [rob_up, rob_low] = stl_eval_mex_pw(this.sig_str, phi_str, trace, tau);
% rob_neg = find(rob_up < 0);
% tau_s = (rob_neg(1, 1) - 1) * Ts;
% % extract the input and output signals of nn controller in the interval [0, tau_s]
% ic_sig_val = ic_sig_val(:, 1:rob_neg(1, 1));
% oc_sig_val = oc_sig_val(:, 1:rob_neg(1, 1));
% return;