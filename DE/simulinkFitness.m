function [fitnessVal, robList] = simulinkFitness(mdlInfo, simConf, searchConf, testSuite)
% SIMULINKFITNESS Calculates fitness of a model with alternative weights using different strategies.
%
% Inputs:
%   mdlInfo - struct containing model-related information:
%       .faultyMdl  - name of the base faulty Simulink model
%       .oriWeights - original weights stored as a cell array per layer
%       .spsWeights - Suspicious weights [layerIdx, postNeuronIdx, preNeuronIdx, oriVal, score]
%
%   simConf - struct containing simulation configuration:
%       .T       - total simulation time
%       .Ts      - sampling time
%       .in_name - input variable names
%       .in_span - input time span
%       .phi     - STL specification
%
%   searchConf - struct with differential evolution search configuration:
%       .geni            - Current generation index
%       .popi            - Current individual index in the population
%       .fitnessMode     - Fitness evaluation mode ('exp', 'cheapincr', etc.)
%       .deFlag          - Identifier flag used for naming/recording
%       .altWeights      - Alternative weights proposed for NN repair
%       .robList         - Cached robustness list (may contain Inf/-Inf)
%       .earlyCutOff     - Whether to stop evaluation early when it becomes impossible to outperform the current best
%       .prevPopFitness  - Previous generation's fitness values for all individuals
%       .peerBestFitness - Best fitness value found in the current generation
%
%   testSuite - struct representing the test suite:
%       .size       - Number of test cases
%       .testCases  - Array of test case structs, each with .sysInputs and .rob
%
% Outputs:
%   fitnessVal - Computed fitness score for the current individual
%   robList    - Robustness values for each test case after applying the patch

% The model is loaded once per worker and kept in fast restart; evaluating an
% individual only pushes its weights into the already-compiled model.
h = fastRobOpen(mdlInfo, simConf);
fastRobSetWeights(h, searchConf.altWeights);

if searchConf.earlyCutOff
    estRobList = nan(testSuite.size, 1);
end

if contains(searchConf.fitnessMode, 'exp')
    oriRobList = [testSuite.testCases.rob]';
    % Reverse iteration improves early termination effectiveness
    for tci = testSuite.size:-1:1
        sysInputs = testSuite.testCases(tci).sysInputs;
        testSuite.testCases(tci).newRob = fastRob(h, sysInputs);
        % Early Cut-off
        if searchConf.earlyCutOff
            estRobList(tci) = testSuite.testCases(tci).newRob;
            estFitnessVal = feval(searchConf.fitnessMode, oriRobList, estRobList);
            if estFitnessVal < searchConf.prevPopFitness(searchConf.popi)
                fitnessVal = estFitnessVal;
                robList = estRobList;
                return;
            end
        end
    end
elseif contains(searchConf.fitnessMode, 'cheapincr')
    posEndIdx = testSuite.sn;
    negStartIdx = testSuite.sn + 1;
    [testSuite.testCases(1:posEndIdx).newRob] = deal(Inf);
    [testSuite.testCases(negStartIdx:end).newRob] = deal(-Inf);
    for tci = negStartIdx:testSuite.size
        sysInputs = testSuite.testCases(tci).sysInputs;
        testSuite.testCases(tci).newRob = fastRob(h, sysInputs);
        if testSuite.testCases(tci).newRob < 0, break; end
    end
    for tci = posEndIdx:-1:1
        sysInputs = testSuite.testCases(tci).sysInputs;
        testSuite.testCases(tci).newRob = fastRob(h, sysInputs);
        if testSuite.testCases(tci).newRob > 0, break; end
    end
elseif strcmp(searchConf.fitnessMode, 'calib')

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
            testSuite.testCases(tci).newRob = fastRob(h, sysInputs);
        end
    end
    
    if ~isempty(posInfi)
        for tci = posInfi:-1:1
            sysInputs = testSuite.testCases(tci).sysInputs;
            testSuite.testCases(tci).newRob = fastRob(h, sysInputs);
        end
    end
end

if strcmp(searchConf.fitnessMode, 'calib')
    searchConf.fitnessMode = 'expdis';
end

fitnessVal = feval(searchConf.fitnessMode, [testSuite.testCases.rob]', [testSuite.testCases.newRob]');
robList = [testSuite.testCases.newRob]';
end
