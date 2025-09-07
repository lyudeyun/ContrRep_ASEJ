function newFolder(folder)

if exist(folder, 'dir') ~= 7
    mkdir(folder);
    disp(['Folder ', folder, ' has been created!']);
else
    disp(['Folder ' folder, ' already exists!']);
end

end