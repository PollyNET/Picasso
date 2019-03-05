function [wvconstUsed, wvconstUsedStd, wvconstUsedInfo] = pollyxt_tropos_select_wvconst(wvconst, wvconstStd, WVCaliInfo, IWVAttri, currentTime, defaults, file)
%pollyxt_tropos_select_wvconst  select the most appropriate water vapor calibration constant to calculate the WVMR and RH.
%   Example:
%       [wvconstUsed, wvconstUsedStd, wvconstUsedInfo] = pollyxt_tropos_select_wvconst(wvconst, wvconstStd, WVCaliInfo, IWVAttri, currentTime, defaults, file)
%   Inputs:
%       wvconst: array
%           water vapor calibration constants. [g*kg^{-1}] 
%       wvconstStd: array
%           uncertainty of water vapor calibration constants. [g*kg^{-1}] 
%       WVCaliInfo: struct
%           source: char
%               data source. ('AERONET', 'MWR' or else)
%           site: char
%               measurement site.
%           datetime: array
%               datetime of applied IWV.
%           PI: char
%           contact: char
%       IWVAttri: struct
%           datetime: array
%               water vapor calibration time. [datenum]
%           WVCaliInfo: cell
%               calibration information for each calibration period.
%           IntRange: matrix
%               index of integration range for calculate the raw IWV from lidar. 
%       currentTime: datenum
%           The creation time for the data netCDF file.
%       defaults: struct
%           defaults configuration. Detailed information can be found in doc/polly_defaults.md 
%       file: char
%           file for saving water vapor calibration results.
%   Outputs:
%       wvconstUsed: float
%           applied water vapor calibration constants.[g*kg^{-1}]  
%       wvconstUsedStd: float
%           uncertainty of applied water vapor calibration constants. [g*kg^{-1}]  
%       wvconstUsedInfo: struct
%           flagCalibrated: logical
%               flag to show whether the applied constant comes from a successful calibration. If not, the result comes from the defaults.
%           IWVInstrument: char
%               the instrument for external standard IWV measurement 
%           nIWVCali: integer
%               number of successful water vapor calibration.
%   History:
%       2018-12-19. First Edition by Zhenping
%   Contact:
%       zhenping@tropos.de

wvconstUsedInfo = struct();
wvconstUsed = NaN;
wvconstUsedStd = NaN;

if isempty(wvconst)
    [wvconstUsed, wvconstUsedStd] = pollyxt_tropos_search_wvconst(currentTime, file, datenum(0,1,7), defaults);
    wvconstUsed = defaults.wvconst;
    wvconstUsedStd = defaults.wvconstStd;
    wvCaliTimeStr = '-999';
    flagWVCali = false;
    IWVInstrument = 'none';
    IWVMeasTimeStr = '-999';
    wvconstUsedInfo.flagCalibrated = false;
    wvconstUsedInfo.IWVInstrument = 'none';
    wvconstUsedInfo.nIWVCali = 0;
elseif sum(~ isnan(wvconst)) == 0
    [wvconstUsed, wvconstUsedStd] = pollyxt_tropos_search_wvconst(currentTime, file, datenum(0,1,7), defaults);
    wvconstUsedStd = defaults.wvconstStd;
    wvconstUsedInfo.flagCalibrated = false;
    wvconstUsedInfo.IWVInstrument = IWVAttri.source;
    wvconstUsedInfo.nIWVCali = 0;
else
    flagCalibrated = ~ isnan(wvconst);
    wvconstUsed = nanmean(wvconst);
    wvconstUsedStd = sqrt(sum(wvconstStd(flagCalibrated).^2)) ./ sum(flagCalibrated);
    wvconstUsedInfo.flagCalibrated = true;
    wvconstUsedInfo.IWVInstrument = IWVAttri.source;
    wvconstUsedInfo.nIWVCali = sum(flagCalibrated);
end

end