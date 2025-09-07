function [U] = crossover(X, V, lb, ub, CR, crossStrategy)
% crossover function performs a crossover operation.
%
% Inputs:
%   X: current population
%   V: population vector mutated by X
%   lb: lower bound
%   ub: upper bound
%   CR: crossover rate
%   crossStrategy: crossover strategy
% Outputs:
%   U: population vector crossovered by X and V

% pop_size: population size; Dim: individual dimension
[pop_size, Dim] = size(X);

switch crossStrategy
    % crossStrategy == 1 (binomial crossover)
    case 1
        for col_i = 1:pop_size
            % jRand in [1, Dim]
            jRand = randi([1, Dim]);
            for j = 1:Dim
                k=rand;
                % let j == jRand to make sure there is at least one U(i,j)
                % is equal to V(i,j)
                if k <= CR||j == jRand
                    U(col_i,j) = V(col_i,j);
                else
                    U(col_i,j) = X(col_i,j);
                end
            end
        end
        % crossStrategy == 2 (exponential crossover)
    case 2
        for col_i=1:pop_size
            % j in [1, Dim]
            j=randi([1, Dim]);
            L = 0;
            U(col_i,:) = X(col_i,:);
            k = rand;
            while(k < CR && L < Dim)
                U(col_i,j) = V(col_i,j);
                j = j + 1;
                if(j > Dim)
                    j = 1;
                end
                L = L + 1;
            end
        end
    otherwise
        error('No matching crossover strategy is found, please reset the value of crossoverStrategy!');
end

% boundary condition handling column by column
for col_i = 1:size(U, 2)
    % set the elements in column col_i which are less than the lower bound as the lower bound
    lb_idx = U(:, col_i) < lb(1, col_i);
    U(lb_idx, col_i) = lb(1, col_i);
    % set the elements in column col_i which are greater than the upper bound as the upper bound
    ub_idx = U(:, col_i) > ub(1, col_i);
    U(ub_idx, col_i) = ub(1, col_i);
end

end
