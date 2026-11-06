function root = repoRoot()
% REPOROOT Root folder of the repository, i.e., the closest folder above this
% file that holds both results/ and util/. The analysis scripts use it to find
% the results, so they can be run from any folder.
root = fileparts(mfilename('fullpath'));
while ~(isfolder(fullfile(root, 'results')) && isfolder(fullfile(root, 'util')))
    parent = fileparts(root);
    if strcmp(parent, root)
        error('repoRoot:notFound', 'No folder with results/ and util/ above %s', mfilename('fullpath'));
    end
    root = parent;
end
end
