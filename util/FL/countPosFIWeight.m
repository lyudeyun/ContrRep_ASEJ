function [layerPosFINum] = countPosFIWeight(diagInfoSuite)
% initMutFLInfo function returns initialized mutFLInfo, hyMCon and hyCon.
%
% Inputs:
%   diagInfoSuite:
% Outputs:
%   layerPosFINum:

testCaseNum = numel(diagInfoSuite);
tsPosFICount = cell(1,testCaseNum);

for tsi = 1:testCaseNum
    frameNum = numel(diagInfoSuite{tsi}.weight2Out);
    % Cumulative processing across the inferences
    % weight2OutSnapShot -> weight2OutSnapShotBinary
    weight2OutSnapShotBinary = cellfun(@(x) double(x ~= 0), diagInfoSuite{tsi}.weight2Out{1}, 'UniformOutput', false);
    tsPosFICount{tsi} = weight2OutSnapShotBinary;
    for fri = 2:frameNum
        % weight2OutSnapShot -> weight2OutSnapShotBinary
        weight2OutSnapShotBinary = cellfun(@(x) double(x ~= 0), diagInfoSuite{tsi}.weight2Out{fri}, 'UniformOutput', false);
        tsPosFICount{tsi} = cellfun(@plus, tsPosFICount{tsi}, weight2OutSnapShotBinary, 'UniformOutput', false);
    end
end

% Cumulative processing across the test cases
posFICount = tsPosFICount{1};
for tsi = 2:testCaseNum
    posFICount = cellfun(@plus, posFICount, tsPosFICount{tsi}, 'UniformOutput', false);
end

layerPosFINum = cellfun(@(x) nnz(x), posFICount);
end