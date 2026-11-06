function [fitnessVal, robList] = nonSimulinkFitness(modelInfo, searchConf, testSuite)
% NONSIMULINKFITNESS Evaluates the fitness of a non-Simulink benchmark.
%
% This function applies the given alternative weights to a neural network controller,
% simulates each test case, and computes the fitness score based on robustness improvements.
%
% Inputs:
%   modelInfo - struct with model-specific information:
%       .bm              - Benchmark name ('UUV', 'MC', etc.)
%       .faultyMdl       - Original NN controller name (YAML format; without '.yml' extension)
%       .spsWeights      - Suspicious weights [layerIdx, postNeuronIdx, preNeuronIdx, oriVal, score]
%
%   searchConf - struct with differential evolution search configuration:
%       .geni            - Current generation index
%       .popi            - Current individual index in the population
%       .fitnessMode     - Fitness evaluation mode ('exp', 'cheapincr', etc.)
%       .deFlag          - Identifier flag used for naming/recording
%       .altWeights      - Alternative weights proposed for NN repair
%       .earlyCutOff     - Whether to stop evaluation early when it becomes impossible to outperform the current best
%       .robList         - Cached robustness list (may contain Inf/-Inf)
%       .prevPopFitness  - Previous generation's fitness values for all individuals
%
%   testSuite - struct representing the test suite:
%       .size       - Number of test cases
%       .testCases  - Array of test case structs, each with .sysInputs and .rob
%
% Outputs:
%   fitnessVal - Computed fitness score for the current individual
%   robList    - Robustness values for each test case after applying the patch

% Generate name for patched NN file
nnName = [modelInfo.faultyMdl, '_g_', num2str(searchConf.geni), '_p_', num2str(searchConf.popi), '_', searchConf.deFlag, '.yml'];

% Apply patch to the neural network
switch modelInfo.bm
    case 'UUV'
        uuvWeightReplace(modelInfo.faultyMdl, nnName, searchConf.altWeights, modelInfo.spsWeights);
    case 'MC'
        mcWeightReplace(modelInfo.faultyMdl, nnName, searchConf.altWeights, modelInfo.spsWeights);
    otherwise
        error('Unsupported benchmark: %s', modelInfo.bm);
end

% Only used when earlyCutOff is enabled; ignored if set to false.
if searchConf.earlyCutOff
    estRobList = nan(testSuite.size, 1); % Used to estimate fitness during early termination
end

% Evaluate robustness
if contains(searchConf.fitnessMode, 'exp')
    oriRobList = [testSuite.testCases.rob]';
    % Reverse iteration improves early termination effectiveness
    for tci = testSuite.size:-1:1
        sysInputs = testSuite.testCases(tci).sysInputs;
        testSuite.testCases(tci).newRob = simulateCase(modelInfo.bm, sysInputs, nnName);
        % Early Cut-off
        if searchConf.earlyCutOff
            estRobList(tci) = testSuite.testCases(tci).newRob;
            estFitnessVal = feval(searchConf.fitnessMode, oriRobList, estRobList);
            if estFitnessVal < searchConf.prevPopFitness(searchConf.popi)
                fitnessVal = estFitnessVal;
                robList = estRobList;
                % Cleanup
                if isfile(nnName), delete(nnName); end
                return;
            end
        end
    end
elseif contains(searchConf.fitnessMode, 'cheapincr')
    [testSuite.testCases(1:testSuite.sn).newRob] = deal(Inf);
    [testSuite.testCases(testSuite.sn+1:end).newRob] = deal(-Inf);
    % Negative cases
    for tci = testSuite.sn+1:testSuite.size
        sysInputs = testSuite.testCases(tci).sysInputs;
        testSuite.testCases(tci).newRob = simulateCase(modelInfo.bm, sysInputs, nnName);
        if testSuite.testCases(tci).newRob < 0, break; end
    end
    % Positive cases
    for tci = testSuite.sn:-1:1
        sysInputs = testSuite.testCases(tci).sysInputs;
        testSuite.testCases(tci).newRob = simulateCase(modelInfo.bm, sysInputs, nnName);
        if testSuite.testCases(tci).newRob > 0, break; end
    end
elseif strcmp(searchConf.fitnessMode, 'calib')

    % Reverse traversal increases the chance of early negative robustness; stop early if surpassing the best is impossible.
    negInfi = find(searchConf.robList == -Inf, 1, 'first');
    posInfi = find(searchConf.robList == Inf, 1, 'last');

    % Reuse previously computed robustness values
    if isempty(posInfi)
        idxRange = 1:negInfi-1;
    elseif isempty(negInfi)
        idxRange = posInfi+1:testSuite.size;
    else
        idxRange = posInfi+1:negInfi-1;
    end

    for tci = idxRange
        testSuite.testCases(tci).newRob = searchConf.robList(tci);
    end

    if ~isempty(negInfi)
        for tci = testSuite.size:-1:negInfi
            sysInputs = testSuite.testCases(tci).sysInputs;
            testSuite.testCases(tci).newRob = simulateCase(modelInfo.bm, sysInputs, nnName);
        end
    end

    if ~isempty(posInfi)
        for tci = posInfi:-1:1
            sysInputs = testSuite.testCases(tci).sysInputs;
            testSuite.testCases(tci).newRob = simulateCase(modelInfo.bm, sysInputs, nnName);
        end
    end
end

if strcmp(searchConf.fitnessMode, 'calib')
    searchConf.fitnessMode = 'expdis';
end

% Compute fitness
fitnessVal = feval(searchConf.fitnessMode, [testSuite.testCases.rob]', [testSuite.testCases.newRob]');
robList = [testSuite.testCases.newRob]';

% Cleanup
if isfile(nnName)
    delete(nnName);
end

    function rob = simulateCase(bench, sysInputs, nnPath)
        % SIMULATECASE Dispatches simulation call based on benchmark
        switch bench
            case 'UUV'
                rob = matlabUUV(sysInputs(1), sysInputs(2), nnPath);
            case 'MC'
                rob = simMatlabMC(sysInputs(1), sysInputs(2), nnPath);
            otherwise
                error('Simulation not defined for benchmark: %s', bench);
        end
    end
end
