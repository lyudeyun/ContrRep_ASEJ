function fastRobSetWeights(h, altWeights)
% FASTROBSETWEIGHTS  Apply a candidate individual's weights to the loaded model.
% Only the suspicious columns change; every other entry of the row keeps its
% original string verbatim, matching replaceWeights bit for bit.
for ri = 1:size(h.rowBlocks, 1)
    sel = find(h.spsWeights(:,1) == h.rowBlocks(ri,1) & ...
               h.spsWeights(:,2) == h.rowBlocks(ri,2));
    entries = h.rowEntries{ri};
    for k = 1:numel(sel)
        entries{1, h.spsWeights(sel(k), 3)} = sprintf('%.16g', altWeights(sel(k)));
    end
    set_param(h.rowPaths{ri}, 'Value', ['[' strjoin(entries, ';') ']']);
end
end
