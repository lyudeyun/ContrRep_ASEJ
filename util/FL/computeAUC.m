function [subAUCInfo, aucInfo] = computeAUC(resFolder, mode)
% COMUPUTEAUC computes normalized sub and full AUC values from DR/FDR.
%
% Inputs:
%   resFolder  - path to folder with *ROC.mat result files
%   mode       - 'DR' (Detection Rate) or 'FDR' (False Detection Rate)
%
% Outputs:
%   subAUCInfo - AUC of 13 correct benchmarks
%   aucInfo    - struct containing normalized full AUCs for each metric

%% the folder stores the results
dirOutput = dir(fullfile(resFolder, '*.mat'));
fileNames = {dirOutput.name};

if strcmp(mode, 'DR')
    appNum = 13;
elseif strcmp(mode, 'FDR')
    % Lower bound
    appNum = 14;
end

subAUCInfo = cellfun(@(x) zeros(13,appNum), cell(5,1), 'UniformOutput', false);
aucInfo = cellfun(@(x) zeros(13,appNum), cell(5,1), 'UniformOutput', false);

for bmi = 1:numel(fileNames)
    
    load(fullfile(resFolder, fileNames{bmi}));

    for mi = 1:5
        for appi = 1:appNum
            if strcmp(mode, 'DR')
                % normalize to the range [0,1]
                subAUCInfo{mi}(bmi,appi) = 5 * trapz(roi_tops, rocDRInfo{mi,appi}(1:numel(roi_tops)))/10000;
                aucInfo{mi}(bmi,appi) = 5 * trapz(tops, rocDRInfo{mi,appi})/10000;
            elseif strcmp(mode, 'FDR')
                % normalize to the range [0,1], I forgot why I started counting from 2.
                subAUCInfo{mi}(bmi,appi) = 5 * trapz(roi_tops(2:end), rocFDRInfo{mi,appi}(2:numel(roi_tops)))/10000;
                aucInfo{mi}(bmi,appi) = 5 * trapz(tops, rocFDRInfo{mi,appi})/10000;
            end
        end
    end
end
end