function [defaults] = pollyxt_noa_read_defaults()
%pollyxt_noa_read_defaults read default settings for pollyxt_dwd
%   Example:
%       [defaults] = pollyxt_noa_read_defaults(file)
%   Inputs:
%       file: char
%   Outputs:
%       defaults:
%           default settings for polly lidar system. More detailed information can be found in doc/polly_defaults.md
%   History:
%       2018-12-19. First Edition by Zhenping
%   Contact:
%       zhenping@tropos.de

defaultFile = 'pollyxt_noa_defaults.json';

if exist(defaultFile, 'file') ~= 2
    error('Default file for pollyxt_noa does not exist!\n%s\n', defaultFile);
end

defaults = loadjson(defaultFile);

end