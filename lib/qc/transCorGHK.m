function [sigTCor, bgTCor] = transCorGHK(sigT, bgT, sigC, bgC, varargin)
% TRANSCOR corrects the effect of different polarization dependent transmission inside the total and depol channel.
%
% USAGE:
%    [sigTCor, bgTCor, sigTCorStd] = transCor(sigEl, bgT, sigC, bgC)
%
% INPUTS:
%    sigT: array
%        signal in total channel.
%    bgT: array
%        background in total channel.
%    sigC: array
%        signal in cross channel.
%    bgC: array
%        background in total channel.
%
% KEYWORDS:
%    transRatioTotal: float
%        transmission ratio of perpendicular and parallel component in 
%        total channel.
%    transRatioTotalStd: float
%        uncertainty of the transmission ratio of perpendicular and 
%        parallel componnet in total channel.
%    transRatioCross: float
%        transmission ratio of perpendicular and parallel component in 
%        cross channel.
%    transRatioCrossStd: float
%        uncertainty of the transmission ratio of perpendicular and 
%        parallel componnet in total channel.
%    polCaliFactor: float
%        depolarization calibration constant.
%    polCaliFacStd: float
%        uncertainty of the depolarization calibration constant.
%
% OUTPUTS:
%    sigTCor: array
%        transmission corrected elastic signal.
%    bgTCor: array
%        background of transmission corrected elastic signal.
%    sigTCorStd: array
%        uncertainty of transmission corrected elastic signal.
%
% REFERENCES:
%    Mattis, I., Tesche, M., Grein, M., Freudenthaler, V., and M�ller, D.: Systematic error of lidar profiles caused by a polarization-dependent receiver transmission: Quantification and error correction scheme, Appl. Opt., 48, 2742-2751, 2009.
%    Freudenthaler, V. About the effects of polarising optics on lidar signals and the Delta90 calibration. Atmos. Meas. Tech., 9, 4181�4255 (2016).
%
% HISTORY:
%    - 2021-05-27: first edition by Zhenping.
%    - 2024-08-14: Change to GHK parameterization by Moritz.
%
% .. Authors: - zhenping@tropos.de, haarig@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'sigT', @isnumeric);
addRequired(p, 'bgT', @isnumeric);
addRequired(p, 'sigC', @isnumeric);
addRequired(p, 'bgC', @isnumeric);
addParameter(p, 'transGT', 1, @isnumeric);
addParameter(p, 'transGR', 1, @isnumeric);
addParameter(p, 'transHT', 0, @isnumeric);
addParameter(p, 'transHR', -1, @isnumeric);
addParameter(p, 'polCaliEta', 1, @isnumeric);
addParameter(p, 'polCaliEtaStd', 0, @isnumeric);

parse(p, sigT, bgT, sigC, bgC, varargin{:});

if ~ isequal(size(sigT), size(sigC))
    error('input signals have different size.')
end

% uncertainty caused by RcStd and RtStd is neglected because usually it
% is very small. 
GT = p.Results.transGT;
GR = p.Results.transGR;
HT = p.Results.transHT;
HR = p.Results.transHR;
eta = p.Results.polCaliEta;
etaStd = p.Results.polCaliEtaStd;
% from Freudenthaler AMT 2016: eq 65 with the denominator from eq 64 to
% avoid a negative signal
sigTCor = (eta .* HR .* sigT - HT .* sigC) ./ (HR*GT - HT*GR);
%sigTCor = (Rc - 1)/(Rc - Rt) .* sigT + ...
%            (1 - Rt)/(Rc - Rt) ./ depolConst .* sigC;
bgTCor = (eta .* HR .* bgT - HT .* bgC) ./ (HR*GT - HT*GR);
%bgTCor = (Rc - 1)/(Rc - Rt) .* bgT + ...
%           (1 - Rt)/(Rc - Rt) ./ depolConst .* bgC;
%sigTCorVar = (sigC ./ depolConst.^2 * (1-Rt) / (Rc-Rt)).^2 .* ...
%                depolConstStd.^2 + ((Rc - 1) / (Rc - Rt)).^2 .* ...
%                (sigT + bgT) + ((1 - Rt) ./ ...
%                (depolConst * (Rc - Rt))).^2 .* (sigC + bgC);

%sigTCorVar(sigTCorVar < 0) = 0;   % convert non-negative
%sigTCorStd = sqrt(sigTCorVar);   % TODO
 
end