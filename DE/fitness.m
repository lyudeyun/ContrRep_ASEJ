function [fitnessVal, robList] = fitness(modelInfo, simConf, searchConf, testSuite)
% FITNESS Evaluates how well the model performs after being patched with alternative weights.
%
% Inputs:
%   modelInfo - struct containing model and test suite information
%       .bm               - benchmark name
%       .bmType           - benchmark type ('simulink' or 'nonSimulink')
%       .faultyMdl        - the faulty Simulink model or NN controller file (YAML) targeted for repair
%       .oriWeights       - original weights of the neural network
%       .spsWeights       - suspicious weights information
%
%   simConf - struct containing simulation configuration
%       .T                - simulation time
%       .Ts               - sampling interval
%       .in_name          - input signal names
%       .in_span          - time span of input signals
%       .phi              - STL specification
%
%   searchConf - struct containing search configuration details
%       .geni             - current generation index
%       .popi             - current individual index
%       .fitnessMode      - mode to calculate fitness ('exp', 'cheapincr', etc.)
%       .deFlag           - differential evolution flag
%       .altWeights       - alternative weights for repair
%       .earlyCutOff     - Whether to stop evaluation early when it becomes impossible to outperform the current best
%       .robList         - Cached robustness list (may contain Inf/-Inf)
%       .prevPopFitness  - Previous generation's fitness values for all individuals
%
% Outputs:
%   fitnessVal - calculated fitness value
%   robList    - robustness values for the current test suite

switch modelInfo.bmType
    case 'simulink'
        [fitnessVal, robList] = simulinkFitness(modelInfo, simConf, searchConf, testSuite);
    case 'nonSimulink'
        [fitnessVal, robList] = nonSimulinkFitness(modelInfo, searchConf, testSuite);
    otherwise
        error('Unsupported benchmark type: %s', modelInfo.bmType);
end
end