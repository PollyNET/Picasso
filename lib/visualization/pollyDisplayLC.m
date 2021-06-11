function pollyDisplayLC(data)
% POLLYDISPLAYLC display lidar calibration constants.
% USAGE:
%    pollyDisplayLC(data)
% INPUTS:
%    data
% EXAMPLE:
% HISTORY:
%    2021-06-11: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

global PicassoConfig CampaignConfig PollyConfig PollyDataInfo

if isempty(data.clFreGrps)
    return;
end

thisTime = mean(data.mTime(data.clFreGrps), 2);
time = data.mTime;
figDPI = PicassoConfig.figDPI;
partnerLabel = config.partnerLabel;
flagWatermarkOn = PicassoConfig.flagWatermarkOn;
yLim355 = config.yLim_LC_355;
yLim532 = config.yLim_LC_532;
yLim1064 = config.yLim_LC_1064;
yLim387 = config.yLim_LC_387;
yLim607 = config.yLim_LC_607;
[xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');
imgFormat = config.imgFormat;

%% 355 nm
flag355 = data.flagFarRangeChannel & data.flag355nmChannel & data.flagTotalChannel;
if (sum(flag355) == 1)
    LC355_klett = data.LC.LC_klett_355;
    LC355_raman = data.LC.LC_raman_355;
    LC355_aeronet = data.LC.LC_aeronet_355;

    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(PicassoConfig.pic_folder, CampaignConfig.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display rcs 
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'time', 'thisTime', 'LC355_klett', 'LC355_raman', 'LC355_aeronet', 'yLim355', 'PicassoConfig', 'CampaignConfig', 'PollyDataInfo', 'xtick', 'xtickstr', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(PicassoConfig.pyBinDir, 'python'), fullfile(pyFolder, 'pollyDisplayLC355FR.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'pollyDisplayLC355FR.py');
    end
    delete(tmpFile);
end

%% 532 nm
flag532 = data.flagFarRangeChannel & data.flag532nmChannel & data.flagTotalChannel;
if (sum(flag532) == 1)
    LC532_klett = data.LC.LC_klett_532;
    LC532_raman = data.LC.LC_raman_532;
    LC532_aeronet = data.LC.LC_aeronet_532;

    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(PicassoConfig.pic_folder, CampaignConfig.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display rcs 
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'time', 'thisTime', 'LC532_klett', 'LC532_raman', 'LC532_aeronet', 'yLim532', 'PicassoConfig', 'CampaignConfig', 'PollyDataInfo', 'xtick', 'xtickstr', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(PicassoConfig.pyBinDir, 'python'), fullfile(pyFolder, 'pollyDisplayLC532FR.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'pollyDisplayLC532FR.py');
    end
    delete(tmpFile);
end

%% 1064 nm
flag1064 = data.flagFarRangeChannel & data.flag1064nmChannel & data.flagTotalChannel;
if (sum(flag1064) == 1)
    LC1064_klett = data.LC.LC_klett_1064;
    LC1064_raman = data.LC.LC_raman_1064;
    LC1064_aeronet = data.LC.LC_aeronet_1064;

    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(PicassoConfig.pic_folder, CampaignConfig.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display rcs 
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'time', 'thisTime', 'LC1064_klett', 'LC1064_raman', 'LC1064_aeronet', 'yLim1064', 'PicassoConfig', 'CampaignConfig', 'PollyDataInfo', 'xtick', 'xtickstr', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(PicassoConfig.pyBinDir, 'python'), fullfile(pyFolder, 'pollyDisplayLC1064FR.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'pollyDisplayLC1064FR.py');
    end
    delete(tmpFile);
end

%% 387 nm
flag387 = data.flagFarRangeChannel & data.flag387nmChannel;
flag355 = data.flagFarRangeChannel & data.flagTotalChannel & data.flag355nmChannel;
if (sum(flag387) == 1) && (sum(flag355) == 1)
    LC387_raman = data.LC.LC_raman_387;

    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(PicassoConfig.pic_folder, CampaignConfig.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display rcs 
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'time', 'thisTime', 'LC387_raman', 'yLim387', 'PicassoConfig', 'CampaignConfig', 'PollyDataInfo', 'xtick', 'xtickstr', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(PicassoConfig.pyBinDir, 'python'), fullfile(pyFolder, 'pollyDisplayLC387FR.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'pollyDisplayLC387FR.py');
    end
    delete(tmpFile);
end

%% 607 nm
flag607 = data.flagFarRangeChannel & data.flag607nmChannel;
flag532 = data.flagFarRangeChannel & data.flagTotalChannel & data.flag532nmChannel;
if (sum(flag607) == 1) && (sum(flag532) == 1)
    LC607_raman = data.LC.LC_raman_607;

    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(PicassoConfig.pic_folder, CampaignConfig.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display rcs 
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'time', 'thisTime', 'LC607_raman', 'yLim607', 'PicassoConfig', 'CampaignConfig', 'PollyDataInfo', 'xtick', 'xtickstr', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(PicassoConfig.pyBinDir, 'python'), fullfile(pyFolder, 'pollyDisplayLC607FR.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'pollyDisplayLC607FR.py');
    end
    delete(tmpFile);
end

end