function [rob, Br] = calRob(mdl, Br, T, Ts, in_name, in_span, phi, sysInputs)
% CALROB Calculates the STL robustness of a Simulink model given input signals and an STL specification.
% By default, simulation is accelerated using the provided Br instance; 
% if Br is empty, a new Breach instance is created from the model.
%
% Inputs:
%   mdl             - Simulink model name (string)
%   T               - total simulation time
%   Ts              - sampling time
%   in_name         - cell array of input signal names
%   in_span         - vector specifying input switching intervals
%   phi             - STL specification
%   sysInputs       - external input signals of the system
%
% Outputs:
%   rob       - robustness value
%   Br        - BreachSimulinkSystem instance

% start simulation from model
if isempty(Br)
    Br = BreachSimulinkSystem(mdl);
    Br.Sys.tspan = 0:Ts:T;
end

if isscalar(unique(in_span))
    con_type = 'UniStep';
    input_gen.cp = T/in_span(1);
else
    con_type = 'VarStep';
    input_gen.cp = T./in_span;
end

input_gen.type = con_type;
Br.SetInputGen(input_gen);

switch con_type
    case 'UniStep'
        for i = 1:numel(in_name)
            for cpi = 0:input_gen.cp - 1
                param_name = sprintf('%s_u%d', in_name{i}, cpi);
                Br.SetParam({param_name}, sysInputs{i}(cpi+1));
            end
        end
    case 'VarStep'
        for i = 1:numel(in_name)
            for cpi = 0:input_gen.cp(i) - 1
                param_name = sprintf('%s_u%d', in_name{i}, cpi);
                Br.SetParam({param_name}, sysInputs{i}(cpi+1));
                if cpi ~= input_gen.cp(i) - 1
                    dt_name = sprintf('%s_dt%d', in_name{i}, cpi);
                    Br.SetParam({dt_name}, in_span(i));
                end
            end
        end
end

% simulation may fail due to unstable AI controller output causing solver divergence
try
    Br.Sim(0:Ts:T);
    rob = Br.CheckSpec(phi);
catch
    rob = -1e6;
    return;
end
end