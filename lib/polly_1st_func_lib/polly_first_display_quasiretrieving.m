function [] = polly_first_display_quasiretrieving(data, taskInfo, config)
%polly_first_display_quasiretrieving display the quasi retrievings results
%   Example:
%       [] = polly_first_display_quasiretrieving(data, taskInfo, config)
%   Inputs:
%       data, taskInfo, config
%   Outputs:
%       
%   History:
%       2018-12-30. First Edition by Zhenping
%   Contact:
%       zhenping@tropos.de
    
global defaults processInfo campaignInfo

quasi_bsc_532 = data.quasi_par_beta_532;
quality_mask_532 = data.quality_mask_532;
height = data.height;
time = data.mTime;
figDPI = processInfo.figDPI;
yLim_Quasi_Params = config.yLim_Quasi_Params;
quasi_beta_cRange_532 = config.zLim_quasi_beta_532;
[xtick, xtickstr] = timelabellayout(data.mTime, 'HH:MM');

if strcmpi(processInfo.visualizationMode, 'matlab')
    %% parameter initialize
    file_quasi_bsc_532 = fullfile(processInfo.pic_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'), sprintf('%s_Quasi_Bsc_532.png', rmext(taskInfo.dataFilename)));
    
    %% visualization
    load('myjet_colormap.mat')

    % Quasi Bsc 532 nm 
    figure('Units', 'Pixels', 'Position', [0, 0, 800, 400], 'Visible', 'off');

    subplot('Position', [0.1, 0.15, 0.8, 0.75]);   % mainframe

    quasi_bsc_532(data.quality_mask_532 ~= 0) = NaN;
    p1 = pcolor(data.mTime, data.height, quasi_bsc_532 * 1e6); hold on;
    set(p1, 'EdgeColor', 'none');
    caxis(quasi_beta_cRange_532);
    xlim([data.mTime(1), data.mTime(end)]);
    ylim(yLim_Quasi_Params);
    xlabel('UTC');
    ylabel('Height (m)');
    title(sprintf('Quasi Backscatter Coefficient at %snm for %s at %s', '532', campaignInfo.name, campaignInfo.location), 'fontweight', 'bold', 'interpreter', 'none');
    set(gca, 'Box', 'on', 'TickDir', 'out');
    set(gca, 'ytick', linspace(yLim_Quasi_Params(1), yLim_Quasi_Params(2), 7), 'yminortick', 'on');
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
    save(tmpFile, 'figDPI', 'quasi_bsc_532', 'quality_mask_532', 'height', 'time', 'quasi_beta_cRange_532', 'yLim_Quasi_Params', 'processInfo', 'campaignInfo', 'taskInfo', 'xtick', 'xtickstr', '-v6');
    flag = system(sprintf('%s %s %s %s', fullfile(processInfo.pyBinDir, 'python'), fullfile(pyFolder, 'polly_first_display_quasiretrieving.py'), tmpFile, saveFolder));
    if flag ~= 0
        warning('Error in executing %s', 'polly_first_display_quasiretrieving.py');
    end
    delete(tmpFile);
    
else
    error('Unknow visualization mode. Please check the settings in pollynet_processing_chain_config.json');
end

end