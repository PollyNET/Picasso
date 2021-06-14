function [LC] = polly_first_lidar_calibration(data, config)
%POLLY_FIRST_LIDAR_CALIBRATION calibrate the lidar system
%Example:
%   [LC] = polly_first_lidar_calibration(data, config)
%Inputs:
%   data.struct
%       More detailed information can be found in doc/pollynet_processing_program.md
%   config: struct
%       More detailed information can be found in doc/pollynet_processing_program.md
%Outputs:
%   LC: struct
%       LC_klett_532: array
%           lidar calibration constants for 30s profile.
%       LC_raman_532: array
%           lidar calibration constants for 30s profile.
%       LC_aeronet_532: array
%           lidar calibration constants for 30s profile.
%       LCStd_klett_532: array
%           lidar calibration constants for 30s profile.
%       LCStd_raman_532: array
%           lidar calibration constants for 30s profile.
%       LCStd_aeronet_532: array
%           lidar calibration constants for 30s profile.
%       LC_start_time: array
%           start time of the lidar calibration period.
%       LC_stop_time: array
%           stop time of the lidar calibration period.
%History:
%   2018-12-24. First Edition by Zhenping
%Contact:
%   zhenping@tropos.de

LC = struct();
LC.LC_klett_532 = [];
LC.LC_raman_532 = [];
LC.LC_aeronet_532 = [];
LC.LC_raman_607 = [];
LC.LCStd_klett_532 = [];
LC.LCStd_raman_532 = [];
LC.LCStd_aeronet_532 = [];
LC.LCStd_raman_607 = [];
LC.LC_start_time = [];
LC.LC_stop_time = [];

if ~ isempty(data.cloudFreeGroups)
    LC.LC_start_time = data.mTime(data.cloudFreeGroups(:, 1));
    LC.LC_stop_time = data.mTime(data.cloudFreeGroups(:, 2));
end

flagChannel532 = config.isFR & config.is532nm & config.isTot;
flagChannel607 = config.isFR & config.is607nm;

% index of full overlap adding half of the smoothing window for klett method
hIndxFullOverlap532 = find(data.height >= config.heightFullOverlap(flagChannel532), 1);
if isempty(hIndxFullOverlap532)
    fprintf('Failure in searching the index of full overlap at %s. Set it to be .\nheightFullOverlap: %f\n', config.channelTag(flagChannel532), config.heightFullOverlap(flagChannel532));
    hIndxFullOverlap532 = 70;
end
hIndxBaseKlett532 = hIndxFullOverlap532 + ceil(config.smoothWin_klett_532/2);
hIndxBaseRaman532 = hIndxFullOverlap532 + ceil(config.smoothWin_raman_532/2);
hIndxBaseAERONET532 = hIndxBaseKlett532;

%% calibrate with klett-retrieved profiles
for iGroup = 1:size(data.cloudFreeGroups, 1)
    LC_klett_532 = NaN;
    LCStd_klett_532 = NaN;

    proIndx = data.cloudFreeGroups(iGroup, 1):data.cloudFreeGroups(iGroup, 2);
    nPros = numel(proIndx);

    % 532 nm
    if ~ isnan(data.aerBsc532_klett(iGroup, 80))
        [molBsc532, molExt532] = rayleigh_scattering(532, data.pressure(iGroup, :), data.temperature(iGroup, :) + 273.17, 380, 70);

        sig532 = squeeze(sum(data.signal(flagChannel532, :, proIndx), 3)) / nPros;

        % AOD
        aerExt532_klett = data.aerExt532_klett(iGroup, :);
        aerExt532_klett(1:hIndxBaseKlett532) = aerExt532_klett(hIndxBaseKlett532);
        aerBsc532_klett = data.aerBsc532_klett(iGroup, :);
        aerAOD532 = nancumsum(aerExt532_klett .* [data.distance0(1), diff(data.distance0)]);
        molAOD532 = nancumsum(molExt532 .* [data.distance0(1), diff(data.distance0)]);

        % round-trip transmission
        trans532 = exp(-2 * (aerAOD532 + molAOD532));
        totBsc532 = molBsc532 + aerBsc532_klett;

        % lidar calibration
        LC_klett_532_Profile = sig532 .* data.distance0.^2 ./ totBsc532 ./ trans532;
        [LC_klett_532, ~, relStd] = mean_stable(LC_klett_532_Profile, config.LCMeanWindow, config.LCMeanMinIndx, config.LCMeanMaxIndx);
        LCStd_klett_532 = LC_klett_532 * relStd;
    end

    % concatenate the results
    LC.LC_klett_532 = cat(1, LC.LC_klett_532, LC_klett_532);
    LC.LCStd_klett_532 = cat(1, LC.LCStd_klett_532, LCStd_klett_532);
end

%% calibrate with raman-retrieved profiles
for iGroup = 1:size(data.cloudFreeGroups, 1)
    LC_raman_532 = NaN;
    LC_raman_607 = NaN;
    LCStd_raman_532 = NaN;
    LCStd_raman_607 = NaN;

    proIndx = data.cloudFreeGroups(iGroup, 1):data.cloudFreeGroups(iGroup, 2);
    nPros = numel(proIndx);

    % 532 nm
    if ~ isnan(data.aerBsc532_raman(iGroup, 80))
        [molBsc532, molExt532] = rayleigh_scattering(532, data.pressure(iGroup, :), data.temperature(iGroup, :) + 273.17, 380, 70);

        % Only take into account of profiles with PMT on
        flagCloudFree = false(size(data.mTime));
        flagCloudFree(proIndx) = true;
        proIndx_607On = flagCloudFree & (~ data.mask607Off);
        sig532 = squeeze(sum(data.signal(flagChannel532, :, proIndx_607On), 3)) / sum(proIndx_607On);

        % AOD
        aerExt532_raman = data.aerBsc532_raman(iGroup, :) * config.LR532;
        % aerExt532_raman(1:hIndxBaseRaman532) = aerExt532_raman(hIndxBaseRaman532);
        aerBsc532_raman = data.aerBsc532_raman(iGroup, :);
        aerAOD532 = nancumsum(aerExt532_raman .* [data.distance0(1), diff(data.distance0)]);
        molAOD532 = nancumsum(molExt532 .* [data.distance0(1), diff(data.distance0)]);

        % round-trip transmission
        trans532 = exp(-2 * (aerAOD532 + molAOD532));
        totBsc532 = molBsc532 + aerBsc532_raman;

        % lidar calibration
        LC_raman_532_Profile = sig532 .* data.distance0.^2 ./ totBsc532 ./ trans532;
        [LC_raman_532, ~, relStd] = mean_stable(LC_raman_532_Profile, config.LCMeanWindow, config.LCMeanMinIndx, config.LCMeanMaxIndx);
        LCStd_raman_532 = LC_raman_532 * relStd;
    end

    % concatenate the results
    LC.LC_raman_532 = cat(1, LC.LC_raman_532, LC_raman_532);
    LC.LCStd_raman_532 = cat(1, LC.LCStd_raman_532, LCStd_raman_532);

    % 607 nm
    if ~ isnan(data.aerBsc532_raman(iGroup, 80))
        [molBsc532, molExt532] = rayleigh_scattering(532, data.pressure(iGroup, :), data.temperature(iGroup, :) + 273.17, 380, 70);
        [molBsc607, molExt607] = rayleigh_scattering(607, data.pressure(iGroup, :), data.temperature(iGroup, :) + 273.17, 380, 70);

        % Only take into account of profiles with PMT on
        flagCloudFree = false(size(data.mTime));
        flagCloudFree(proIndx) = true;
        proIndx_607On = flagCloudFree & (~ data.mask607Off);
        sig607 = squeeze(sum(data.signal(flagChannel607, :, proIndx_607On), 3)) / sum(proIndx_607On);

        % AOD
        aerExt532_raman = data.aerBsc532_raman(iGroup, :) * config.LR532;
        aerExt607_raman = aerExt532_raman * (532/607) .^ config.angstrexp;
        aerAOD532 = nancumsum(aerExt532_raman .* [data.distance0(1), diff(data.distance0)]);
        aerAOD607 = nancumsum(aerExt607_raman .* [data.distance0(1), diff(data.distance0)]);
        molAOD532 = nancumsum(molExt532 .* [data.distance0(1), diff(data.distance0)]);
        molAOD607 = nancumsum(molExt607 .* [data.distance0(1), diff(data.distance0)]);

        % round-trip transmission
        trans_532_607 = exp(- (aerAOD532 + molAOD532 + aerAOD607 + molAOD607));
        totBsc532 = molBsc532;

        % lidar calibration
        LC_raman_607_Profile = transpose(smooth(sig607 .* data.distance0.^2, config.smoothWin_raman_532)) ./ totBsc532 ./ trans_532_607;
        [LC_raman_607, ~, relStd] = mean_stable(LC_raman_607_Profile, config.LCMeanWindow, config.LCMeanMinIndx, config.LCMeanMaxIndx);
        LCStd_raman_607 = LC_raman_607 * relStd;
    end

    % concatenate the results
    LC.LC_raman_607 = cat(1, LC.LC_raman_607, LC_raman_607);
    LC.LCStd_raman_607 = cat(1, LC.LCStd_raman_607, LCStd_raman_607);
end

%% calibrate with constrained-AOD-retrieved profiles
for iGroup = 1:size(data.cloudFreeGroups, 1)
    LC_aeronet_532 = NaN;
    LCStd_aeronet_532 = NaN;

    proIndx = data.cloudFreeGroups(iGroup, 1):data.cloudFreeGroups(iGroup, 2);
    nPros = numel(proIndx);

    % 532 nm
    if ~ isnan(data.aerBsc532_aeronet(iGroup, 80))
        [molBsc532, molExt532] = rayleigh_scattering(532, data.pressure(iGroup, :), data.temperature(iGroup, :) + 273.17, 380, 70);

        sig532 = squeeze(sum(data.signal(flagChannel532, :, proIndx), 3)) / nPros;

        % AOD
        aerExt532_aeronet = data.aerExt532_aeronet(iGroup, :);
        aerExt532_aeronet(1:hIndxBaseAERONET532) = aerExt532_aeronet(hIndxBaseAERONET532);
        aerBsc532_aeronet = data.aerBsc532_aeronet(iGroup, :);
        aerAOD532 = nancumsum(aerExt532_aeronet .* [data.distance0(1), diff(data.distance0)]);
        molAOD532 = nancumsum(molExt532 .* [data.distance0(1), diff(data.distance0)]);

        % round-trip transmission
        trans532 = exp(-2 * (aerAOD532 + molAOD532));
        totBsc532 = molBsc532 + aerBsc532_aeronet;

        % lidar calibration
        LC_aeronet_532_Profile = sig532 .* data.distance0.^2 ./ totBsc532 ./ trans532;
        [LC_aeronet_532, ~, relStd] = mean_stable(LC_aeronet_532_Profile, config.LCMeanWindow, config.LCMeanMinIndx, config.LCMeanMaxIndx);
        LCStd_aeronet_532 = LC_aeronet_532 * relStd;
    end

    % concatenate the results
    LC.LC_aeronet_532 = cat(1, LC.LC_aeronet_532, LC_aeronet_532);
    LC.LCStd_aeronet_532 = cat(1, LC.LCStd_aeronet_532, LCStd_aeronet_532);
end

end