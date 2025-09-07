% based on the paper "Differential Evolution Algorithm With Strategy
% Adaptation for Global Numerical Optimization"
clear;
close all;
clc;

% population size
NP = 100;
% max generation
maxGen = 500;
% current generation
Gen = 1;
% dimension of an individual
Dim = 20;
% lb
lb = -30 * ones(1, Dim);
% ub
ub = 30 * ones(1, Dim);
% scaling factor
F = 0.5;
% crossover rate
CR = 0.3;
% test function index
index = 3;
% mutation strategy
mutationStrategy = 1;
% crossover strategy
crossStrategy = 1;
%% initialization
% each row represents an individual.
X = (ub - lb).*rand(NP, Dim) + lb; 
%% DE
for Gen = 1:maxGen
    for i = 1:NP
        % the fitness value of X(i)
        fitnessX(i) = testFun(X(i,:), index);
    end
    % obtain the best fitness value up to now
    [fitnessbestX, indexbestX] = min(fitnessX);
    % the individual that leads to the best fitness value 
    bestX = X(indexbestX, :);
    % mutation
    V = mutation(X, bestX, F, mutationStrategy); 
    % crossover
    U=crossover(X, V, lb, ub, CR, crossStrategy); 
    % selection
    for i = 1:NP
        fitnessU(i) = testFun(U(i,:), index);
        if fitnessU(i) <= fitnessX(i)
            X(i,:) = U(i,:);
            fitnessX(i) = fitnessU(i);
            if fitnessU(i) < fitnessbestX
                bestX = U(i,:);
                fitnessbestX = fitnessU(i);
            end
        end
    end
    % disp the best fitness of this generation
    fprintf('%d      %f\n',Gen,fitnessbestX);  
    bestfitness(Gen) = fitnessbestX;
end
% plot the best fitness value of each generation 
plot(bestfitness);
xlabel('Gen');
ylabel('bestfitness');