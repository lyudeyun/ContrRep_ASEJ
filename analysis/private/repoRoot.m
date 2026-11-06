function root = repoRoot()
% REPOROOT Root folder of the repository, i.e., the closest folder above this
% file that holds util/ and src/ContrRep.m. The analysis scripts read
% <root>/results from there, so they can be run from any folder.
root = fileparts(mfilename('fullpath'));
while ~(isfolder(fullfile(root, 'util')) && isfile(fullfile(root, 'src', 'ContrRep.m')))
    parent = fileparts(root);
    if strcmp(parent, root)
        error('repoRoot:notFound', 'No folder with util/ and src/ContrRep.m above %s', mfilename('fullpath'));
    end
    root = parent;
end
if ~isfolder(fullfile(root, 'results'))
    error('repoRoot:noResults', ['No results/ folder in %s: run the experiments first ' ...
        '(see the README), which write their results there.'], root);
end
end
