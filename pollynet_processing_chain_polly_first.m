function [report] = pollynet_processing_chain_pollyxt_first(taskInfo, config)
%POLLYNET_PROCESSING_CHAIN_POLLYXT_first processing the data from pollyxt_first
%   Example:
%       [report] = pollynet_processing_chain_pollyxt_first(taskInfo, config)
%   Inputs:
%       taskInfo, config
%   Outputs:
%       report: cell array
%           information about each figure.
%   History:
%       2018-12-17. First edition by Zhenping  
%       2019-10-15. Adapted version by Holger
%   Contact:
%       zhenping@tropos.de
report = cell(0);
global processInfo campaignInfo defaults

%% create folder
results_folder = fullfile(processInfo.results_folder, campaignInfo.name, datestr(taskInfo.dataTime, 'yyyy'), datestr(taskInfo.dataTime, 'mm'), datestr(taskInfo.dataTime, 'dd'));
pic_folder = fullfile(processInfo.pic_folder, campaignInfo.name, datestr(taskInfo.dataTime, 'yyyy'), datestr(taskInfo.dataTime, 'mm'), datestr(taskInfo.dataTime, 'dd'));
if ~ exist(results_folder, 'dir')
    fprintf('Create a new folder to saving the results for %s at %s\n%s\n', campaignInfo.name, datestr(taskInfo.dataTime, 'yyyymmdd HH:MM'), results_folder);
    mkdir(results_folder);
end
if ~ exist(pic_folder, 'dir')
    fprintf('Create a new folder to saving the plots for %s\n%s\n', campaignInfo.name, datestr(taskInfo.dataTime, 'yyyymmdd HH:MM'), pic_folder);
    mkdir(pic_folder);
end

%% read data
fprintf('\n[%s] Start to read %s data.\n%s\n', tNow(), campaignInfo.name, taskInfo.dataFilename);
data = polly_read_rawdata(fullfile(taskInfo.todoPath, taskInfo.dataPath, taskInfo.dataFilename), config, processInfo.flagDeleteData);
if isempty(data.rawSignal)
    warning('No measurement data in %s for %s.\n', taskInfo.dataFilename, campaignInfo.name);
    return;
end
fprintf('[%s] Finish reading data.\n', tNow());

%% read laserlogbook file
laserlogbookFile = fullfile(taskInfo.todoPath, taskInfo.dataPath, sprintf('%s.laserlogbook.txt', taskInfo.dataFilename));
fprintf('\n[%s] Start to read %s laserlogbook data.\n%s\n', tNow(), campaignInfo.name, laserlogbookFile);
monitorStatus = pollyxt_first_read_laserlogbook(laserlogbookFile, config, processInfo.flagDeleteData);
data.monitorStatus = monitorStatus;
fprintf('[%s] Finish reading laserlogbook.\n', tNow);

%% pre-processing
fprintf('\n[%s] Start to preprocess %s data.\n', tNow(), campaignInfo.name);
data = pollyxt_first_preprocess(data, config);
fprintf('[%s] Finish signal preprocessing.\n', tNow());

%% saturation detection
fprintf('\n[%s] Start to detect signal saturation.\n', tNow());
flagSaturation = pollyxt_first_saturationdetect(data, config);
data.flagSaturation = flagSaturation;
fprintf('\n[%s] Finish.\n', tNow());

%% depol calibration
%  fprintf('\n[%s] Start to calibrate %s depol channel.\n', tNow(), campaignInfo.name);
%  [data, depCaliAttri] = pollyxt_first_depolcali(data, config, taskInfo);
%  data.depCaliAttri = depCaliAttri;
%  fprintf('[%s] Finish depol calibration.\n', tNow());

%% cloud screening
fprintf('\n[%s] Start to cloud-screen.\n', tNow());
flagChannel532FR = config.isFR & config.is532nm & config.isTot;
PCR532FR = squeeze(data.signal(flagChannel532FR, :, :)) ./ repmat(data.mShots(flagChannel532FR, :), numel(data.height), 1) * 150 / data.hRes;

flagCloudFree8km_FR = polly_cloudscreen(data.height, PCR532FR, config.maxSigSlope4FilterCloud, [config.heightFullOverlap(flagChannel532FR), 7000]);

data.flagCloudFree8km = flagCloudFree8km_FR;
fprintf('[%s] Finish cloud-screen.\n', tNow());

%% overlap estimation
fprintf('\n[%s] Start to estimate the overlap function.\n', tNow());
[data, overlapAttri] = pollyxt_first_overlap(data, config);
fprintf('[%s] Finish.\n', tNow());

%% split the cloud free profiles into continuous subgroups
fprintf('\n[%s] Start to split the cloud free profiles.\n', tNow());
cloudFreeGroups = pollyxt_first_splitcloudfree(data, config);
if isempty(cloudFreeGroups)
    fprintf('No qualified cloud-free groups were found.\n');
else
    fprintf('%d cloud-free groups were found.\n', size(cloudFreeGroups, 1));
end
data.cloudFreeGroups = cloudFreeGroups;
fprintf('[%s] Finish.\n', tNow());

%% load meteorological data
fprintf('\n[%s] Start to load meteorological data.\n', tNow());
[temperature, pressure, relh, meteorAttri] = pollyxt_first_readmeteor(data, config);
data.temperature = temperature;
data.pressure = pressure;
data.relh = relh;
data.meteorAttri = meteorAttri;
fprintf('[%s] Finish.\n', tNow());

%% load AERONET data
fprintf('\n[%s] Start to load AERONET data.\n', tNow());
AERONET = struct();
[AERONET.datetime, AERONET.AOD_1640, AERONET.AOD_1020, AERONET.AOD_870, AERONET.AOD_675, AERONET.AOD_500, AERONET.AOD_440, AERONET.AOD_380, AERONET.AOD_340, AERONET.wavelength, AERONET.IWV, AERONET.angstrexp440_870, AERONET.AERONETAttri] = read_AERONET(config.AERONETSite, [floor(data.mTime(1)) - 1, floor(data.mTime(1)) + 1], '15');
data.AERONET = AERONET;
fprintf('[%s] Finish.\n', tNow());

%% rayleigh fitting
fprintf('\n[%s] Start to apply rayleigh fitting.\n', tNow());
[data.refHIndx532, data.dpIndx532] = pollyxt_first_rayleighfit(data, config);
fprintf('Number of reference height for 532 nm: %2d\n', sum(~ isnan(data.refHIndx532(:)))/2);
fprintf('[%s] Finish.\n', tNow());

%% optical properties retrieving
fprintf('\n[%s] Start to retrieve aerosol optical properties.\n', tNow());
meteorStr = '';
for iMeteor = 1:length(meteorAttri.dataSource)
    meteorStr = [meteorStr, ' ', meteorAttri.dataSource{iMeteor}];
end
fprintf('Meteorological file : %s.\n', meteorStr);

%Manipulated in a way that eltrans is there....
[data.el532, data.bgEl532] = pollyxt_first_transratioCor(data, config);
fprintf('data.rawSignal');
% TODO: replace the total 532nm signal with elastic 532 nm signal
disp(data)
[data.aerBsc532_klett, data.aerExt532_klett] = pollyxt_first_klett(data, config);
[data.aerBsc532_aeronet, data.aerExt532_aeronet, data.LR532_aeronet, data.deltaAOD532] = pollyxt_first_constrainedklett(data, AERONET, config);   % constrain Lidar Ratio
[data.aerBsc532_raman, data.aerExt532_raman, data.LR532_raman] = pollyxt_first_raman(data, config);
fprintf('[%s] Finish.\n', tNow());

%% water vapor calibration
% get IWV from other instruments
% fprintf('\n[%s] Start to water vapor calibration.\n', tNow());
% [data.IWV, IWVAttri] = pollyxt_ift_read_IWV(data, config);
% data.IWVAttri = IWVAttri;
% [wvconst, wvconstStd, wvCaliInfo] = pollyxt_ift_wv_calibration(data, config);
% % if not successful wv calibration, choose the default values
% [data.wvconstUsed, data.wvconstUsedStd, data.wvconstUsedInfo] = pollyxt_ift_select_wvconst(wvconst, wvconstStd, data.IWVAttri, polly_parsetime(taskInfo.dataFilename, config.dataFileFormat), fullfile(processInfo.results_folder, campaignInfo.name, config.wvCaliFile), config.flagUsePreviousLC);
% [data.wvmr, data.rh, ~, data.WVMR, data.RH] = pollyxt_ift_wv_retrieve(data, config, wvCaliInfo.IntRange);
% fprintf('[%s] Finish.\n', tNow());

%% lidar calibration
fprintf('\n[%s] Start to lidar calibration.\n', tNow());
LC = pollyxt_first_lidar_calibration(data, config);
data.LC = LC;
LCUsed = struct();
[LCUsed.LCUsed532, LCUsed.LCUsedTag532, LCUsed.flagLCWarning532, LCUsed.LCUsed607, LCUsed.LCUsedTag607, LCUsed.flagLCWarning607] = pollyxt_first_mean_LC(data, config, taskInfo, fullfile(processInfo.results_folder, config.pollyVersion));
data.LCUsed = LCUsed;
fprintf('[%s] Finish.\n', tNow());

%% attenuated backscatter
fprintf('\n[%s] Start to calculate attenuated backscatter.\n', tNow());
[att_beta_532, att_beta_607] = pollyxt_first_att_beta(data, config);
data.att_beta_532 = att_beta_532;
data.att_beta_607 = att_beta_607;
fprintf('[%s] Finish.\n', tNow());

%% quasi-retrieving
 fprintf('\n[%s] Start to retrieve high spatial-temporal resolved backscatter coeff. and vol.Depol with quasi-retrieving method.\n', tNow());
 [data.quasi_par_beta_532, data.quality_mask_532, quasiAttri] = pollyxt_first_quasiretrieve(data, config);
 data.quasiAttri = quasiAttri;
 fprintf('[%s] Finish.\n', tNow());

%% quasi-retrieving V2 (with using Raman signal)
% fprintf('\n[%s] Start to retrieve high spatial-temporal resolved backscatter coeff. and vol.Depol with quasi-retrieving method (Version 2).\n', tNow());
% [data.quasi_par_beta_355_V2, data.quasi_par_beta_532_V2, data.quasi_par_beta_1064_V2, data.quasi_parDepol_532_V2, ~, data.quasi_ang_532_1064_V2, data.quality_mask_355_V2, data.quality_mask_532_V2, data.quality_mask_1064_V2, data.quality_mask_volDepol_532_V2, quasiAttri_V2] = pollyxt_ift_quasiretrieve_V2(data, config);
% data.quasiAttri_V2 = quasiAttri_V2;
% fprintf('[%s] Finish.\n', tNow());

% %% target classification
% fprintf('\n[%s] Start to aerosol target classification.\n', tNow());
% tc_mask = pollyxt_ift_targetclassi(data, config);
% data.tc_mask = tc_mask;
% fprintf('[%s] Finish.\n', tNow());
% 
% %% target classification with quasi-retrieving V2
% fprintf('\n[%s] Start to aerosol target classification with quasi results (V2).\n', tNow());
% tc_mask_V2 = pollyxt_ift_targetclassi_V2(data, config);
% data.tc_mask_V2 = tc_mask_V2;
% fprintf('[%s] Finish.\n', tNow());

%% saving calibration results
if processInfo.flagEnableCaliResultsOutput

    fprintf('\n[%s] Start to save calibration results.\n', tNow());

    %% save lidar calibration results
    pollyxt_first_save_LC_nc(data, taskInfo, config);
    pollyxt_first_save_LC_txt(data, taskInfo, config);

    %% save water vapor calibration results
    %pollyxt_ift_save_wvconst(wvconst, wvconstStd, wvCaliInfo, data.IWVAttri, taskInfo.dataFilename, data.wvconstUsed, data.wvconstUsedStd, fullfile(processInfo.results_folder, campaignInfo.name, config.wvCaliFile));
    
    fprintf('[%s] Finish.\n', tNow());

end

%% saving retrieving results
if processInfo.flagEnableResultsOutput

    if processInfo.flagDeletePreOutputs
        % delete the previous outputs
        % This is only necessary when you run the code on the live server, 
        % where the polly data keep being updated every now and then. If the 
        % previous outputs were not cleared, it will piled up to a huge amount.
        fprintf('\n[%s] Start to delete previous nc files.\n', tNow());

        % search files associated with the same start time
        fileList = listfile(fullfile(processInfo.results_folder, ...
                                     campaignInfo.name, ...
                                     datestr(data.mTime(1), 'yyyy'), ...
                                     datestr(data.mTime(1), 'mm'), ...
                                     datestr(data.mTime(1), 'dd')), ...
                            sprintf('%s.*.nc', rmext(taskInfo.dataFilename)));
        
        % delete the files
        for iFile = 1:length(fileList)
            delete(fileList{iFile});
        end
    end

    fprintf('\n[%s] Start to save retrieving results.\n', tNow());

    %% save overlap results
    saveFile = fullfile(processInfo.results_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'), sprintf('%s_overlap.nc', rmext(taskInfo.dataFilename)));
    pollyxt_first_save_overlap(data, taskInfo, config, overlapAttri, saveFile);

    %% save aerosol optical results
    pollyxt_first_save_retrieving_results(data, taskInfo, config);

    %% save water vapor mixing ratio and relative humidity
    %pollyxt_ift_save_WVMR_RH(data, taskInfo, config);

    %% save attenuated backscatter
    pollyxt_first_save_att_bsc(data, taskInfo, config);
    
    %% save volume depolarization ratio
    %pollyxt_ift_save_voldepol(data, taskInfo, config);

    %% save quasi results
    pollyxt_first_save_quasi_results(data, taskInfo, config);
    
    %% save quasi results V2
    %pollyxt_ift_save_quasi_results_V2(data, taskInfo, config);

    %% save target classification results
    %pollyxt_ift_save_tc(data, taskInfo, config);

    %% save target classification results V2
    %pollyxt_ift_save_tc_V2(data, taskInfo, config);

    fprintf('[%s] Finish.\n', tNow());
end

%% visualization
if processInfo.flagEnableDataVisualization

    if processInfo.flagDeletePreOutputs
        % delete the previous outputs
        % This is only necessary when you run the code on the live server, 
        % where the polly data keep being updated every now and then. If the 
        % previous outputs were not cleared, it will piled up to a huge amount.
        fprintf('\n[%s] Start to delete previous figures.\n', tNow());

        % search files associated with the same start time
        fileList = listfile(fullfile(processInfo.pic_folder, ...
                                     campaignInfo.name, ...
                                     datestr(data.mTime(1), 'yyyy'), ...
                                     datestr(data.mTime(1), 'mm'), ...
                                     datestr(data.mTime(1), 'dd')), ...
                            sprintf('%s.*.png', rmext(taskInfo.dataFilename)));
        
        % delete the files
        for iFile = 1:length(fileList)
            delete(fileList{iFile});
        end
    end

    fprintf('\n[%s] Start to visualize results.\n', tNow());

    %% display monitor status
    disp('Display housekeeping')
    pollyxt_first_display_monitor(data, taskInfo, config);

    %% display signal
    disp('Display RCS and volume depolarization ratio')
    pollyxt_first_display_rcs(data, taskInfo, config);

    %% display saturation and cloud free tags
    disp('Display signal flags')
    pollyxt_first_display_saturation(data, taskInfo, config);

    %% display overlap
    disp('Display overlap')
    pollyxt_first_display_overlap(data, taskInfo, overlapAttri, config);

    %% display optical profiles
    disp('Display profiles')
    pollyxt_first_display_retrieving(data, taskInfo, config);

    %% display attenuated backscatter
    disp('Display attnuated backscatter')
    pollyxt_first_display_att_beta(data, taskInfo, config);
     %% display quasi backscatter, particle depol and angstroem exponent 
    disp('Display quasi parameters')
    pollyxt_first_display_quasiretrieving(data, taskInfo, config);
    
    %% display quasi backscatter, particle depol and angstroem exponent V2 
    %disp('Display quasi parameters V2')
   % pollyxt_ift_display_quasiretrieving_V2(data, taskInfo, config);

    %% target classification
    %disp('Display target classifications')
    %pollyxt_ift_display_targetclassi(data, taskInfo, config);

    %% target classification V2
    %disp('Display target classifications V2')
    %pollyxt_ift_display_targetclassi_V2(data, taskInfo, config);

    %% display lidar calibration constants
    disp('Display Lidar constants.')
    pollyxt_first_display_lidarconst(data, taskInfo, config);
    
    %% display Long-term lidar constant with logbook
    disp('Display Long-Term lidar cosntants.')
    pollyxt_first_display_longterm_cali(taskInfo, config);

    fprintf('[%s] Finish.\n', tNow());
end

%% get report
report = pollyxt_first_results_report(data, taskInfo, config);

%% debug output
if isfield(processInfo, 'flagDebugOutput')
    if processInfo.flagDebugOutput
        save(fullfile(processInfo.results_folder, campaignInfo.name, datestr(taskInfo.dataTime, 'yyyy'), datestr(taskInfo.dataTime, 'mm'), datestr(taskInfo.dataTime, 'dd'), [rmext(taskInfo.dataFilename), '.mat']));
    end
end

end