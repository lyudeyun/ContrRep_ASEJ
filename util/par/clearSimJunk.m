function clearSimJunk(homeFolder, brFolder)
% CLEARSIMJUNK Removes temporary and auto-generated files from Simulink model runs,
% including .slx, .slxc, .autosave, versioned files, and the slprj directory 
% to keep the workspace clean.
%
% Input:
%

if ~isempty(brFolder)
    delete(fullfile(['breach/Ext/ModelsData/', '*_breach.slx']));
end

delete(fullfile([homeFolder, '*.slx']));
delete(fullfile([homeFolder, '*.slx.autosave']));
delete(fullfile([homeFolder, '*.slx.r202*']));
delete(fullfile([homeFolder, '*_breach.slxc']));
rmdir('slprj', 's');
end