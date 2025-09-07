function V = mutation(X, bestX, F, mutationStrategy)
% mutation function performs a mutation operation.
%
% Inputs:
%   X: current population
%   bestX: the individual whose fitness value is best in current generation
%   lb: lower bound
%   ub: upper bound
%   F: scaling factor
%   mutationStrategy: mutation strategy
% Outputs:
%   V: mutation vector mutated by X

[pop_size, ~] = size(X);

% To ensure the individual diversity, in the process of generating new individuals in the population,
% nrandI different random numbers are generated, none of which are equal to i. That is,
% the nrandI old individuals randomly selected to generate i-th new individual cannot include the i-th old individual.

for pop_i = 1:pop_size
    % 5 different random numbers are generated within [1, pop_size], none of which are equal to pop_i.
    nrandI = 5;
    r = randi([1, pop_size], 1, nrandI);
    for j = 1:nrandI
        equalr(j) = sum(r == r(j));
    end
    equali = sum(r == pop_i);
    equalall = sum(equalr) + equali;
    % if the generated random numbers have duplicates or are equal to pop_i, the
    % random numbers need to be regenerated.
    while(equalall > nrandI)
        r=randi([1, pop_size], 1, nrandI);
        for j = 1:nrandI
            equalr(j) = sum(r == r(j));
        end
        equali=sum(r == pop_i);
        equalall = sum(equalr) + equali;
    end

    % Note:
    % (1) From paper: "Investigation of Mutation Strategies in Differential
    %     Evolution for Solving Global Optimization Problems"
    %     "A Unified Differential Evolution Algorithm for Global Optimization"
    % (2) For simplification, I set two F to the same value;
    % (3) There are two many variants of mutation strategy. So I only
    %     implement some of them.

    switch mutationStrategy
        case 1
            % mutationStrategy = 1: DE/rand/1;
            V(pop_i,:) = X(r(1),:) + F*(X(r(2),:) - X(r(3),:));
        case 2
            % mutationStrategy = 2: DE/rand/2;
            V(pop_i,:) = X(r(1),:) + F*(X(r(2),:) - X(r(3),:)) + F*(X(r(4),:) - X(r(5),:));
        case 3
            % mutationStrategy = 3: DE/best/1;
            V(pop_i,:) = bestX + F*(X(r(1),:) - X(r(2),:));
        case 4
            % mutationStrategy = 4: DE/best/2;
            V(pop_i,:) = bestX + F*(X(r(1),:) - X(r(2),:)) + F*(X(r(3),:) - X(r(4),:));
        case 5
            % mutationStrategy = 5: DE/cur-to-rand/1;
            V(pop_i,:) = X(pop_i,:) + F*(X(r(1),:) - X(pop_i,:)) + F*(X(r(2),:) - X(r(3),:));
        case 6
            % mutationStrategy = 6: DE/cur-to-rand/2;
            V(pop_i,:) = X(pop_i,:) + F*(X(r(1),:) - X(pop_i,:)) + F*(X(r(2),:) - X(r(3),:)) + F*(X(r(4),:) - X(r(5),:));
        case 7
            % mutationStrategy = 7: DE/cur-to-best/1;
            V(pop_i,:) = X(pop_i,:) + F*(bestX - X(pop_i,:)) + F*(X(r(1),:) - X(r(2),:));
        case 8
            % mutationStrategy = 8: DE/cur-to-best/2;
            V(pop_i,:) = X(pop_i,:) + F*(bestX - X(pop_i,:)) + F*(X(r(1),:) - X(r(2),:)) + F*(X(r(3),:) - X(r(4),:));
        case 9
            % mutationStrategy = 9: DE/rand-to-best/1;
            V(pop_i,:) = X(r(1),:) + F*(bestX - X(pop_i,:)) + F*(X(r(2),:) - X(r(3),:));
        case 10
            % mutationStrategy = 10: DE/rand-to-best/2;
            V(pop_i,:) = X(r(1),:) + F*(bestX - X(pop_i,:)) + F*(X(r(2),:) - X(r(3),:)) + F*(X(r(4),:) - X(r(5),:));
        otherwise
            error('No matching mutation strategy is found, please reset the value of mutationStrategy!');
    end

end
