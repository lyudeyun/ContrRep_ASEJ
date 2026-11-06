function s = meanStdCells(m, sdv, decimals, higherIsBetter)
% MEANSTDCELLS "\meanstd{mean}{std}" table cells, joined by " & ".
% The best rounded mean (highest, or lowest if higherIsBetter is false) is
% marked with \best; a NaN mean (no results) gives "--".
txt = arrayfun(@(x) fmtFixed(x, decimals), m, 'UniformOutput', false);
val = cellfun(@str2double, txt);
ok = ~isnan(m);
if higherIsBetter, best = max(val(ok)); else, best = min(val(ok)); end
cells = cell(1, numel(m));
for k = 1:numel(m)
    if ~ok(k)
        cells{k} = '--';
        continue;
    end
    cells{k} = sprintf('\\meanstd{%s}{%s}', txt{k}, fmtFixed(sdv(k), decimals));
    if val(k) == best
        cells{k} = ['\best ' cells{k}];
    end
end
s = strjoin(cells, ' & ');
end
