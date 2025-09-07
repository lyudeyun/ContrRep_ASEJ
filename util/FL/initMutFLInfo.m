function [mutFLInfo, hyMCon, hyCon] = initMutFLInfo(weight, nnStru, mutNum, spsMetricList)
% INITMUTFLINFO Returns initialized mutFLInfo, hyMCon and hyCon.
%
% Inputs
%   weight: cell array, weight{li}(i,j) is weight from neuron j in li-1 to i in li  
%   nnStru: nn structure
%   mutNum: number of mutants
%   spsMetricList: suspiciousness metrics used for FL
%
% Outputs
%   mutFLInfo: an empty FL results of all mutants
%   hyMCon: an empty struct array
%   hyCon: an empty struct array

% initialize the mutFLInfo
metNum = numel(spsMetricList);
allLNum = numel(nnStru);
hLNum = allLNum - 1;

% initialize the exeSpectrum based on current nn structure
exeSpectrum = cell(1,allLNum);

% skip input weights
for li = 2:hLNum
    [iNum, jNum] = deal(nnStru(li), nnStru(li-1));
    exeSpectrum{li} = repmat({zeros(1,4)}, iNum, jNum);
end

% [li, i, j, oriVal, spsScore]
spsWeightList = [];
for li = 2:hLNum
    iNum = nnStru(li);
    jNum = nnStru(li-1);
    for i = 1:iNum
        for j = 1:jNum
            spsWeightList(end+1,:) = [li, i, j, weight{li}(i,j), 0];
        end
    end
end

% hyper config (hyCon) includes 12 hyper-param combinations and their corresponding FL results
hyCon(1,12) = struct( ...
    'window', [], ...
    'esMode', [], ...
    'topkMode', [], ...
    'topk', [], ...
    'exeSpectrum', [], ...
    'spsMetric', [], ...
    'spsWeightList', [], ...
    'recallList', []);

% assign exeSpectrum to each struct in hyCon
for hci = 1:12
    hyCon(hci).spsWeightList = spsWeightList;
    hyCon(hci).exeSpectrum = exeSpectrum;  % directly assign exeSpectrum to each struct
end

% SpectAcle_uw
[hyCon(1,1:5).window] = deal(0);
[hyCon(1,1:5).esMode] = deal('topk');
[hyCon(1,1:5).topkMode] = deal('fixedRatio4TS');
[hyCon(1,1:5).topk] = deal(0.1,0.2,0.3,0.4,0.5);

% Act-based_uw
hyCon(1,6).window = 0;
hyCon(1,6).esMode = 'activated';
hyCon(1,6).topkMode = 'N/A';
hyCon(1,6).topk = 'N/A';

% SpectAcle_w
[hyCon(1,7:11).window] = deal(1);
[hyCon(1,7:11).esMode] = deal('topk');
[hyCon(1,7:11).topkMode] = deal('fixedRatio4TS');
[hyCon(1,7:11).topk] = deal(0.1,0.2,0.3,0.4,0.5);

% Act-based_w
hyCon(1,12).window = 1;
hyCon(1,12).esMode = 'activated';
hyCon(1,12).topkMode = 'N/A';
hyCon(1,12).topk = 'N/A';

% % Random
% hyCon(1,13).window = 'N/A';
% hyCon(1,13).esMode = 'N/A';
% hyCon(1,13).topkMode = 'N/A';
% hyCon(1,13).topk = 'N/A';

hyMCon = repmat(hyCon, metNum, 1);

for mi = 1:metNum
    [hyMCon(mi,:).spsMetric] = deal(spsMetricList{mi});
end

% design new data structure to store the FL results of each mutant
% actually, we only need topmax, i.e., the last cell of spsWeightInfoCell.
mutFLInfo = cell(1,mutNum);
curMutInfo = struct('mutName', [], 'mutInfo', [], 'hyMCon', hyMCon);

for muti = 1:mutNum
    mutFLInfo{1,muti} = curMutInfo;
end
end