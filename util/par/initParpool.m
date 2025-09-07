function initParpool(coreNum)
% INITPARPOOL Starts a parallel pool with given coreNum if needed or mismatched.
%
% Input:
%   coreNum - Number of parallel workers to launch (e.g., 10, 20)

pool = gcp('nocreate');

% Start a new pool only if none exists, or if size mismatch
if isempty(pool) || pool.NumWorkers ~= coreNum
    if ~isempty(pool)
        delete(pool);
    end
    parpool(coreNum);
end
end