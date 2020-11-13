function pollyxt_ift_display_targetclassi(data, taskInfo, config)
%POLLYXT_IFT_DISPLAY_TARGETCLASSI display the target classification reuslts
%Example:
%   pollyxt_ift_display_targetclassi(data, taskInfo, config)
%Inputs:
%   data, taskInfo, config
%History:
%   2018-12-30. First Edition by Zhenping
%Contact:
%   zhenping@tropos.de

global processInfo defaults campaignInfo

%% read data
TC_mask = data.tc_mask;
height = data.height;
time = data.mTime;
figDPI = processInfo.figDPI;
yLim_Quasi_Params = config.yLim_Quasi_Params;
[xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');
imgFormat = config.imgFormat;
partnerLabel = config.partnerLabel;
flagWatermarkOn = processInfo.flagWatermarkOn;

if strcmpi(processInfo.visualizationMode, 'matlab')
    %% initialization 
    fileTC = fullfile(processInfo.pic_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'), sprintf('%s_TC.%s', rmext(taskInfo.dataFilename), imgFormat));

    %% visualization
    load('TC_colormap.mat')

    % 355 nm FR
    figure('Units', 'Pixels', 'Position', [0, 0, 800, 400], 'Visible', 'off');

    subplot('Position', [0.1, 0.15, 0.6, 0.6]);   % mainframe

    TC_mask = double(TC_mask);
    p1 = pcolor(data.mTime, data.height, TC_mask); hold on;
    set(p1, 'EdgeColor', 'none');
    caxis([0, 11]);
    xlim([data.mTime(1), data.mTime(end)]);
    ylim(yLim_Quasi_Params);
    xlabel('UTC', 'FontSize', 15);
    ylabel('Height (m)', 'FontSize', 15);
    title(sprintf('Target Classification from %s at %s', taskInfo.pollyVersion, campaignInfo.location), 'fontweight', 'bold', 'interpreter', 'none', 'FontSize', 15);
    set(gca, 'Box', 'on', 'TickDir', 'out');
    set(gca, 'ytick', linspace(yLim_Quasi_Params(1), yLim_Quasi_Params(2), 6), 'yminortick', 'on');
    set(gca, 'xtick', xtick, 'xticklabel', xtickstr);
    text(-0.04, -0.13, sprintf('%s', datestr(data.mTime(1), 'yyyy-mm-dd')), 'Units', 'Normal', 'FontSize', 12);
    text(0.90, -0.13, sprintf('Version: %s', processInfo.programVersion), 'Units', 'Normal', 'FontSize', 12);

    % colorbar
    TC_TickLabels = {'No signal', ...
                    'Clean atmosphere', ...
                    'Non-typed particles/low conc.', ...
                    'Aerosol: small', ...
                    'Aerosol: large, spherical', ...
                    'Aerosol: mixture, partly non-spherical', ...
                    'Aerosol: large, non-spherical', ...
                    'Cloud: non-typed', ...
                    'Cloud: water droplets', ...
                    'Cloud: likely water droplets', ...
                    'Cloud: ice crystals', ...
                    'Cloud: likely ice crystals'};
    c = colorbar('position', [0.71, 0.15, 0.01, 0.6]); 
    colormap(TC_colormap);
    titleHandle = get(c, 'Title');
    set(titleHandle, 'string', '');
    set(c, 'TickDir', 'out', 'Box', 'on', 'FontSize', 10);
    set(c, 'ytick', (0.5:1:11.5)/12*11, 'yticklabel', TC_TickLabels);

    set(findall(gcf, '-property', 'fontname'), 'fontname', processInfo.fontname);

    export_fig(gcf, fileTC, '-transparent', sprintf('-r%d', processInfo.figDPI), '-painters');
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

    %% display rcs 
    tmpFile = fullfile(tmpFolder, [basename(tempname), '.mat']);
    save(tmpFile, 'figDPI', 'TC_mask', 'height', 'time', 'yLim_Quasi_Params', 'processInfo', 'campaignInfo', 'taskInfo', 'xtick', 'xtickstr', 'imgFormat', 'flagWatermarkOn', 'partnerLabel', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(processInfo.pyBinDir, 'python'), fullfile(pyFolder, 'pollyxt_ift_display_targetclassi.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'pollyxt_ift_display_targetclassi.py');
    end
    delete(tmpFile);

else
    error('Unknow visualization mode. Please check the settings in pollynet_processing_chain_config.json');
end

end