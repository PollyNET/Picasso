function polly_1st_displayHousekeeping(data)
% POLLY_1ST_DISPLAYHOUSEKEEPING display housekeeping data.
%
% USAGE:
%    polly_1st_displayHousekeeping(data)
%
% INPUTS:
%    data: struct
%
% HISTORY:
%    - 2021-06-09: first edition by Zhenping
%
% .. Authors: - zhenping@tropos.de

global CampaignConfig PicassoConfig PollyConfig PollyDataInfo

if isempty(data.rawSignal)
    return;
end

try

    [xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');
    monitorStatus = data.monitorStatus;
    figDPI = PicassoConfig.figDPI;
    mTime = data.mTime;
    imgFormat = PollyConfig.imgFormat;
    partnerLabel = PollyConfig.partnerLabel;
    flagWatermarkOn = PicassoConfig.flagWatermarkOn;

    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(PicassoConfig.pic_folder, CampaignConfig.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display monitor status
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'monitorStatus', 'PicassoConfig', 'CampaignConfig', 'PollyDataInfo', 'xtick', 'xtickstr', 'mTime', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(PicassoConfig.pyBinDir, 'python'), fullfile(pyFolder, 'polly_1st_displayHousekeeping.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'polly_1st_displayHousekeeping.py');
    end
    delete(tmpFile);

catch
    warning('Failure in producing housekeeping plot.');
end

end