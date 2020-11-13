function polly_1v2_display_quasiretrieving_V2(data, taskInfo, config)
%polly_1v2_display_quasiretrieving_V2 display the quasi retrievings results
%Example:
%   polly_1v2_display_quasiretrieving_V2(data, taskInfo, config)
%Inputs:
%   data, taskInfo, config
%History:
%   2018-12-30. First Edition by Zhenping
%Contact:
%   zhenping@tropos.de

global defaults processInfo campaignInfo

%% read data
quasi_bsc_532 = data.quasi_par_beta_532_V2;
quality_mask_532 = data.quality_mask_532_V2;
quasi_pardepol_532 = data.quasi_parDepol_532_V2;
height = data.height;
time = data.mTime;
figDPI = processInfo.figDPI;
partnerLabel = config.partnerLabel;
flagWatermarkOn = processInfo.flagWatermarkOn;
yLim_Quasi_Params = config.yLim_Quasi_Params;
quasi_Par_DR_cRange_532 = config.zLim_quasi_Par_DR_532;
quasi_beta_cRange_532 = config.zLim_quasi_beta_532;
[xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');
imgFormat = config.imgFormat;
colormap_basic = config.colormap_basic;

if strcmpi(processInfo.visualizationMode, 'matlab')
    %% parameter initialize
    file_quasi_bsc_532 = fullfile(processInfo.pic_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'), sprintf('%s_Quasi_Bsc_532_V2.%s', rmext(taskInfo.dataFilename), imgFormat));
    file_quasi_parDepol_532 = fullfile(processInfo.pic_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'), sprintf('%s_Quasi_PDR_532_V2.%s', rmext(taskInfo.dataFilename), imgFormat));

    %% visualization
    load('myjet_colormap.mat')

    % Quasi Bsc 532 nm 
    figure('Units', 'Pixels', 'Position', [0, 0, 800, 400], 'Visible', 'off');

    subplot('Position', [0.1, 0.15, 0.8, 0.75]);   % mainframe

    quasi_bsc_532 = data.quasi_par_beta_532_V2;
    quasi_bsc_532(data.quality_mask_532_V2 ~= 0) = NaN;
    p1 = pcolor(data.mTime, data.height, quasi_bsc_532 * 1e6); hold on;
    set(p1, 'EdgeColor', 'none');
    caxis(config.quasi_beta_cRange_532);
    xlim([data.mTime(1), data.mTime(end)]);
    ylim([0, 12000]);
    xlabel('UTC');
    ylabel('Height (m)');
    title(sprintf('Quasi Backscatter Coefficient (V2) at %snm for %s at %s', '532', campaignInfo.name, campaignInfo.location), 'fontweight', 'bold', 'interpreter', 'none');
    set(gca, 'Box', 'on', 'TickDir', 'out');
    set(gca, 'ytick', 0:2000:12000, 'yminortick', 'on');
    [xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');
    set(gca, 'xtick', xtick, 'xticklabel', xtickstr);
    text(-0.04, -0.13, sprintf('%s', datestr(data.mTime(1), 'yyyy-mm-dd')), 'Units', 'Normal');
    text(0.90, -0.13, sprintf('Version %s', processInfo.programVersion), 'Units', 'Normal');

    % colorbar
    c = colorbar('Position', [0.92, 0.15, 0.02, 0.75]);
    set(gca, 'TickDir', 'out', 'Box', 'on');
    titleHandle = get(c, 'Title');
    set(titleHandle, 'string', 'Mm^{-1}*Sr^{-1}');

    colormap(myjet);

    set(findall(gcf, '-property', 'fontname'), 'fontname', processInfo.fontname);

    export_fig(gcf, file_quasi_bsc_532, '-transparent', sprintf('-r%d', processInfo.figDPI), '-painters');
    close();

    % Quasi particle depolarization ratio at 532 nm 
    figure('Units', 'Pixels', 'Position', [0, 0, 800, 400], 'Visible', 'off');

    subplot('Position', [0.1, 0.15, 0.8, 0.75]);   % mainframe

    quasi_pardepol_532 = data.quasi_parDepol_532_V2;
    quasi_pardepol_532(data.quality_mask_532_V2 ~= 0) = NaN;
    p1 = pcolor(data.mTime, data.height, quasi_pardepol_532); hold on;
    set(p1, 'EdgeColor', 'none');
    caxis(config.quasi_Par_DR_cRange_532);
    xlim([data.mTime(1), data.mTime(end)]);
    ylim([0, 12000]);
    xlabel('UTC');
    ylabel('Height (m)');
    title(sprintf('Quasi Particle Depolarization Ratio (V2) at %snm for %s at %s', '532', campaignInfo.name, campaignInfo.location), 'fontweight', 'bold', 'interpreter', 'none');
    set(gca, 'Box', 'on', 'TickDir', 'out');
    set(gca, 'ytick', 0:2000:12000, 'yminortick', 'on');
    [xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');
    set(gca, 'xtick', xtick, 'xticklabel', xtickstr);
    text(-0.04, -0.13, sprintf('%s', datestr(data.mTime(1), 'yyyy-mm-dd')), 'Units', 'Normal');
    text(0.90, -0.13, sprintf('Version %s', processInfo.programVersion), 'Units', 'Normal');

    % colorbar
    c = colorbar('Position', [0.92, 0.15, 0.02, 0.75]);
    set(gca, 'TickDir', 'out', 'Box', 'on');
    titleHandle = get(c, 'Title');
    set(titleHandle, 'string', '');

    colormap(myjet);

    set(findall(gcf, '-property', 'fontname'), 'fontname', processInfo.fontname);

    export_fig(gcf, file_quasi_parDepol_532, '-transparent', sprintf('-r%d', processInfo.figDPI), '-painters');
    close();

elseif strcmpi(processInfo.visualizationMode, 'python')

    fprintf('Display the results with Python.\n');
    pyFolder = fileparts(mfilename('fullpath'));   % folder of the python scripts for data visualization
    tmpFolder = fullfile(parentFolder(mfilename('fullpath'), 3), 'tmp');
    saveFolder = fullfile(processInfo.pic_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'));

    % create tmp folder by force, if it does not exist.
    if ~ exist(tmpFolder, 'dir')
        fprintf('Create the tmp folder to save the temporary results.\n');
        mkdir(tmpFolder);
    end

    %% display quasi results
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'quasi_bsc_532', 'quality_mask_532', 'quasi_pardepol_532', 'height', 'time', 'quasi_beta_cRange_532', 'quasi_Par_DR_cRange_532', 'yLim_Quasi_Params', 'processInfo', 'campaignInfo', 'taskInfo', 'xtick', 'xtickstr', 'imgFormat', 'colormap_basic', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(processInfo.pyBinDir, 'python'), fullfile(pyFolder, 'polly_1v2_display_quasiretrieving_V2.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'polly_1v2_display_quasiretrieving_V2.py');
    end
    delete(tmpFile);

else
    error('Unknow visualization mode. Please check the settings in pollynet_processing_chain_config.json');
end

end