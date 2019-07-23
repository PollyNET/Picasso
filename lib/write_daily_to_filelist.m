function [] = write_daily_to_filelist(pollyType, saveFolder, todoFolder, year, month, day, writeMode)
%write_daily_to_filelist description
%   Example:
%       [] = write_daily_to_filelist(pollyType, saveFolder, todoFolder, year, month, day, writeMode)
%   Inputs:
%       pollyType: char
%           polly instrument.
%       saveFolder: char
%           polly data folder. 
%           e.g., /oceanethome/pollyxt
%       todoFolder: char
%           the todolist folder.
%           e.g., /home/picasso/Pollynet_Processing_Chain/todo_filelist
%       year: integer
%       month: integer
%       day: integer
%       writeMode: char
%           If writeMode was 'a', the polly data info will be appended. If 'w', a new todofile will be created.
%   Outputs:
%       
%   History:
%       2019-07-21. First Edition by Zhenping
%   Contact:
%       zhenping@tropos.de

if ~ exist('writeMode', 'var')
    writeMode = 'w';
end

%% search zip files
files = dir(fullfile(saveFolder, pollyType, 'data_zip', sprintf('%04d%02d', year, month), sprintf('%04d_%02d_%02d*.nc.zip', year, month, day)));

for iFile = 1:length(files)

    % if there are multiple files in a day, other entries will be appended. 
    if (iFile > 1) && (writeMode == 'w')
        writeMode = 'a';
    end

    write_single_to_filelist(pollyType, fullfile(saveFolder, pollyType, 'data_zip', sprintf('%04d%02d', year, month), files(iFile).name), todoFolder, writeMode)
end

end