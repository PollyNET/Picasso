function [el355, bgEl355] = pollyxt_ift_transratioCor_UV(data, config)
%POLLYXT_IFT_TRANSRATIOCOR_UV correct the effects of non-ideal transmission ratio in total channel to retrieve the real elastic signal.
%Example:
%   [el355, bgEl355] = pollyxt_ift_transratioCor_UV(data, config)
%Inputs:
%   data.struct
%       More detailed information can be found in doc/pollynet_processing_program.md
%   config: struct
%       More detailed information can be found in doc/pollynet_processing_program.md
%Outputs:
%   el355: matrix
%       elastic signal with transmission ratio correction.
%   bgEl355: matrix
%       background elastic signal with transmission ratio correction.
%History:
%   2021-01-19. First Edition by Zhenping
%Contact:
%   zhenping@tropos.de

el355 = NaN(size(data.signal, 2), size(data.signal, 3));
bgEl355 = NaN(size(data.signal, 2), size(data.signal, 3));

if isempty(data.rawSignal)
    return;
end

%% 355 nm
flagChannel355 = config.is355nm & config.isTot & config.isFR;
flagChannel355Cross = config.is355nm & config.isCross & config.isFR;

[el355, bgEl355, ~] = polly_trans_correct(squeeze(data.signal(flagChannel355, :, :)), squeeze(data.bg(flagChannel355, :, :)), squeeze(data.signal(flagChannel355Cross, :, :)), squeeze(data.bg(flagChannel355Cross, :, :)), config.TR(flagChannel355), 0, config.TR(flagChannel355Cross), 0, data.depol_cal_fac_355, data.depol_cal_fac_std_355);

end