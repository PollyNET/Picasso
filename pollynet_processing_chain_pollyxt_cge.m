function [report] = pollynet_processing_chain_pollyxt_cge(taskInfo, config)
%POLLYNET_PROCESSING_CHAIN_POLLYXT_cge processing the data from pollyxt_cge
%	Example:
%		[report] = pollynet_processing_chain_pollyxt_cge(taskInfo, config)
%	Inputs:
%		taskInfo, config
%	Outputs:
%		report: cell array
%           information about each figure.
%	History:
%		2018-12-17. First edition by Zhenping   
%	Contact:
%		zhenping@tropos.de

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
monitorStatus = pollyxt_cge_read_laserlogbook(laserlogbookFile, config, processInfo.flagDeleteData);
data.monitorStatus = monitorStatus;
fprintf('[%s] Finish reading laserlogbook.\n', tNow);

%% pre-processing
fprintf('\n[%s] Start to preprocess %s data.\n', tNow(), campaignInfo.name);
data = pollyxt_cge_preprocess(data, config);
fprintf('[%s] Finish signal preprocessing.\n', tNow());

%% saturation detection
fprintf('\n[%s] Start to detect signal saturation.\n', tNow());
flagSaturation = pollyxt_cge_saturationdetect(data, config);
data.flagSaturation = flagSaturation;
fprintf('\n[%s] Finish.\n', tNow());

%% depol calibration
fprintf('\n[%s] Start to calibrate %s depol channel.\n', tNow(), campaignInfo.name);
[data, depCaliAttri] = pollyxt_cge_depolcali(data, config, taskInfo);
data.depCaliAttri = depCaliAttri;
fprintf('[%s] Finish depol calibration.\n', tNow());

%% cloud screening
fprintf('\n[%s] Start to cloud-screen.\n', tNow());
flagChannel532FR = config.isFR & config.is532nm & config.isTot;
PCR532FR = squeeze(data.signal(flagChannel532FR, :, :)) ./ repmat(data.mShots(flagChannel532FR, :), numel(data.height), 1) * 150 / data.hRes;

flagCloudFree8km_FR = polly_cloudscreen(data.height, PCR532FR, config.maxSigSlope4FilterCloud, [config.heightFullOverlap(flagChannel532FR), 7000]);

data.flagCloudFree8km = flagCloudFree8km_FR;
fprintf('[%s] Finish cloud-screen.\n', tNow());

%% overlap estimation
fprintf('\n[%s] Start to estimate the overlap function.\n', tNow());
[data, overlapAttri] = pollyxt_cge_overlap(data, config);
fprintf('[%s] Finish.\n', tNow());

%% split the cloud free profiles into continuous subgroups
fprintf('\n[%s] Start to split the cloud free profiles.\n', tNow());
cloudFreeGroups = pollyxt_cge_splitcloudfree(data, config);
if isempty(cloudFreeGroups)
    fprintf('No qualified cloud-free groups were found.\n');
else
    fprintf('%d cloud-free groups were found.\n', size(cloudFreeGroups, 1));
end
data.cloudFreeGroups = cloudFreeGroups;
fprintf('[%s] Finish.\n', tNow());

%% load meteorological data
fprintf('\n[%s] Start to load meteorological data.\n', tNow());
[temperature, pressure, relh, meteorAttri] = pollyxt_cge_readmeteor(data, config);
data.temperature = temperature;
data.pressure = pressure;
data.relh = relh;
data.meteorAttri = meteorAttri;
fprintf('[%s] Finish.\n', tNow());

%% load AERONET data
fprintf('\n[%s] Start to load AERONET data.\n', tNow());
AERONET = struct();
[AERONET.datetime, AERONET.AOD_1640, AERONET.AOD_1020, AERONET.AOD_870, AERONET.AOD_675, AERONET.AOD_500, AERONET.AOD_440, AERONET.AOD_380, AERONET.AOD_340, AERONET.wavelength, AERONET.IWV, AERONET.angstrexp440_870, AERONET.AERONETAttri] = read_AERONET(config.AERONETSite, floor(data.mTime(1)), '15');
data.AERONET = AERONET;
fprintf('[%s] Finish.\n', tNow());

%% rayleigh fitting
fprintf('\n[%s] Start to apply rayleigh fitting.\n', tNow());
[data.refHIndx355, data.refHIndx532, data.refHIndx1064, data.dpIndx355, data.dpIndx532, data.dpIndx1064] = pollyxt_cge_rayleighfit(data, config);
fprintf('Number of reference height for 355 nm: %2d\n', sum(~ isnan(data.refHIndx355(:)))/2);
fprintf('Number of reference height for 532 nm: %2d\n', sum(~ isnan(data.refHIndx532(:)))/2);
fprintf('Number of reference height for 1064 nm: %2d\n', sum(~ isnan(data.refHIndx1064(:)))/2);
fprintf('[%s] Finish.\n', tNow());

%% optical properties retrieving
fprintf('\n[%s] Start to retrieve aerosol optical properties.\n', tNow());
meteorStr = '';
for iMeteor = 1:length(meteorAttri.dataSource)
    meteorStr = [meteorStr, ' ', meteorAttri.dataSource{iMeteor}];
end
fprintf('Meteorological file : %s.\n', meteorStr);

[data.el532, data.bgEl532] = pollyxt_cge_transratioCor(data, config);

% TODO: replace the total 532nm signal with elastic 532 nm signal
[data.aerBsc355_klett, data.aerBsc532_klett, data.aerBsc1064_klett, data.aerExt355_klett, data.aerExt532_klett, data.aerExt1064_klett] = pollyxt_cge_klett(data, config);
[data.aerBsc355_aeronet, data.aerBsc532_aeronet, data.aerBsc1064_aeronet, data.aerExt355_aeronet, data.aerExt532_aeronet, data.aerExt1064_aeronet, data.LR355_aeronet, data.LR532_aeronet, data.LR1064_aeronet, data.deltaAOD355, data.deltaAOD532, data.deltaAOD1064] = pollyxt_cge_constrainedklett(data, AERONET, config);   % constrain Lidar Ratio
[data.aerBsc355_raman, data.aerBsc532_raman, data.aerBsc1064_raman, data.aerExt355_raman, data.aerExt532_raman, data.aerExt1064_raman, data.LR355_raman, data.LR532_raman, data.LR1064_raman] = pollyxt_cge_raman(data, config);
[data.voldepol532_klett, data.pardepol532_klett, data.pardepolStd532_klett, data.voldepol532_raman, data.pardepol532_raman, data.pardepolStd532_raman, data.moldepol532, data.moldepolStd532, data.flagDefaultMoldepol532] = pollyxt_cge_depolratio(data, config);
[data.ang_ext_355_532_raman, data.ang_bsc_355_532_raman, data.ang_bsc_532_1064_raman, data.ang_bsc_355_532_klett, data.ang_bsc_532_1064_klett] = pollyxt_cge_angstrexp(data, config);
fprintf('[%s] Finish.\n', tNow());

%% lidar calibration
fprintf('\n[%s] Start to lidar calibration.\n', tNow());
LC = pollyxt_cge_lidar_calibration(data, config);
data.LC = LC;
LCUsed = struct();
[LCUsed.LCUsed355, LCUsed.LCUsedTag355, LCUsed.flagLCWarning355, LCUsed.LCUsed532, LCUsed.LCUsedTag532, LCUsed.flagLCWarning532, LCUsed.LCUsed1064, LCUsed.LCUsedTag1064, LCUsed.flagLCWarning1064, LCUsed.LCUsed387, LCUsed.LCUsedTag387, LCUsed.flagLCWarning387, LCUsed.LCUsed607, LCUsed.LCUsedTag607, LCUsed.flagLCWarning607] = pollyxt_cge_mean_LC(data, config, taskInfo, fullfile(processInfo.results_folder, config.pollyVersion));
data.LCUsed = LCUsed;
fprintf('[%s] Finish.\n', tNow());

%% attenuated backscatter
fprintf('\n[%s] Start to calculate attenuated backscatter.\n', tNow());
[att_beta_355, att_beta_532, att_beta_1064, att_beta_387, att_beta_607] = pollyxt_cge_att_beta(data, config);
data.att_beta_355 = att_beta_355;
data.att_beta_532 = att_beta_532;
data.att_beta_1064 = att_beta_1064;
data.att_beta_387 = att_beta_387;
data.att_beta_607 = att_beta_607;
fprintf('[%s] Finish.\n', tNow());

%% quasi-retrieving
fprintf('\n[%s] Start to retrieve high spatial-temporal resolved backscatter coeff. and vol.Depol with quasi-retrieving method.\n', tNow());
[data.quasi_par_beta_355, data.quasi_par_beta_532, data.quasi_par_beta_1064, data.quasi_parDepol_532, data.volDepol_532, data.quasi_ang_532_1064, data.quality_mask_355, data.quality_mask_532, data.quality_mask_1064, data.quality_mask_volDepol_532, quasiAttri] = pollyxt_cge_quasiretrieve(data, config);
data.quasiAttri = quasiAttri;
fprintf('[%s] Finish.\n', tNow());

%% quasi-retrieving V2 (with using Raman signal)
fprintf('\n[%s] Start to retrieve high spatial-temporal resolved backscatter coeff. and vol.Depol with quasi-retrieving method (Version 2).\n', tNow());
[data.quasi_par_beta_355_V2, data.quasi_par_beta_532_V2, data.quasi_par_beta_1064_V2, data.quasi_parDepol_532_V2, ~, data.quasi_ang_532_1064_V2, data.quality_mask_355_V2, data.quality_mask_532_V2, data.quality_mask_1064_V2, data.quality_mask_volDepol_532_V2, quasiAttri_V2] = pollyxt_cge_quasiretrieve_V2(data, config);
data.quasiAttri_V2 = quasiAttri_V2;
fprintf('[%s] Finish.\n', tNow());

%% target classification
fprintf('\n[%s] Start to aerosol target classification.\n', tNow());
tc_mask = pollyxt_cge_targetclassi(data, config);
data.tc_mask = tc_mask;
fprintf('[%s] Finish.\n', tNow());

%% target classification with quasi-retrieving V2
fprintf('\n[%s] Start to aerosol target classification with quasi results (V2).\n', tNow());
tc_mask_V2 = pollyxt_cge_targetclassi_V2(data, config);
data.tc_mask_V2 = tc_mask_V2;
fprintf('[%s] Finish.\n', tNow());

%% saving results
if processInfo.flagEnableResultsOutput

    fprintf('\n[%s] Start to save results.\n', tNow());

    %% save overlap results
    saveFile = fullfile(processInfo.results_folder, campaignInfo.name, datestr(data.mTime(1), 'yyyy'), datestr(data.mTime(1), 'mm'), datestr(data.mTime(1), 'dd'), sprintf('%s_overlap.nc', rmext(taskInfo.dataFilename)));
    pollyxt_cge_save_overlap(data, taskInfo, config, overlapAttri, saveFile);

    %% save aerosol optical results
    pollyxt_cge_save_retrieving_results(data, taskInfo, config);

    %% save lidar calibration results
    pollyxt_cge_save_LC_nc(data, taskInfo, config);
    pollyxt_cge_save_LC_txt(data, taskInfo, config);

    %% save attenuated backscatter
    pollyxt_cge_save_att_bsc(data, taskInfo, config);
    
    %% save volume depolarization ratio
    pollyxt_cge_save_voldepol(data, taskInfo, config);

    %% save quasi results
    pollyxt_cge_save_quasi_results(data, taskInfo, config);
    
    %% save quasi results V2
    pollyxt_cge_save_quasi_results_V2(data, taskInfo, config);

    %% save target classification results
    pollyxt_cge_save_tc(data, taskInfo, config);

    %% save target classification results V2
    pollyxt_cge_save_tc_V2(data, taskInfo, config);

    fprintf('[%s] Finish.\n', tNow());
end

%% visualization
if processInfo.flagEnableDataVisualization
    
    fprintf('\n[%s] Start to visualize results.\n', tNow());

    %% display monitor status
    disp('Display housekeeping')
    pollyxt_cge_display_monitor(data, taskInfo, config);

    %% display signal
    disp('Display RCS and volume depolarization ratio')
    pollyxt_cge_display_rcs(data, taskInfo, config);

    %% display saturation and cloud free tags
    disp('Display signal flags')
    pollyxt_cge_display_saturation(data, taskInfo, config);

    %% display optical profiles
    disp('Display profiles')
    pollyxt_cge_display_retrieving(data, taskInfo, config);

    %% display attenuated backscatter
    disp('Display attnuated backscatter')
    pollyxt_cge_display_att_beta(data, taskInfo, config);

    %% display quasi backscatter, particle depol and angstroem exponent 
    disp('Display quasi parameters')
    pollyxt_cge_display_quasiretrieving(data, taskInfo, config);
    
    %% display quasi backscatter, particle depol and angstroem exponent V2 
    disp('Display quasi parameters V2')
    pollyxt_cge_display_quasiretrieving_V2(data, taskInfo, config);

    %% target classification
    disp('Display target classifications')
    pollyxt_cge_display_targetclassi(data, taskInfo, config);

    %% target classification V2
    disp('Display target classifications V2')
    pollyxt_cge_display_targetclassi_V2(data, taskInfo, config);

    %% display lidar calibration constants
    disp('Display Lidar constants.')
    pollyxt_cge_display_lidarconst(data, taskInfo, config);
    
    %% display Long-term lidar constant with logbook
    disp('Display Long-Term lidar cosntants.')
    pollyxt_cge_display_longterm_cali(taskInfo, config);

    fprintf('[%s] Finish.\n', tNow());
end

%% get report
report = pollyxt_cge_results_report(data, taskInfo, config);

%% debug output
if isfield(processInfo, 'flagDebugOutput')
    if processInfo.flagDebugOutput
        save(fullfile(processInfo.results_folder, campaignInfo.name, datestr(taskInfo.dataTime, 'yyyy'), datestr(taskInfo.dataTime, 'mm'), datestr(taskInfo.dataTime, 'dd'), [rmext(taskInfo.dataFilename), '.mat']));
    end
end

end