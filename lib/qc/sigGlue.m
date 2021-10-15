function [sigGl] = sigGlue(sigFR, sigNR, sigRatio, height, normRange)
% SIGGLUE glue near-range and far-range signal.
%
% USAGE:
%    sigGl = sigGlue(sigFR, sigNR, height, normRange)
%
% INPUTS:
%    sigFR: matrix (height * time)
%        far-range signal
%    sigNR: matrix (height * time)
%        near-range signal.
%    sigRatio: numeric
%        ratio of lidar constants between near-range and far-range signal.
%    height: array
%        height above ground. (m)
%    normRange: array
%        signal normalization range. (m)
%
% OUTPUTS:
%    sigGl: matrix (height * time)
%        glued signal.
%
% HISTORY:
%    - 2021-05-22: first edition by Zhenping
%
% .. Authors: - zhenping@tropos.de

sigGl = NaN(size(sigFR));

if (~ isempty(normRange)) && (~ isempty(sigRatio))

    bottomIndx = find(height >= normRange(1), 1);
    topIndx = find(height >= normRange(end), 1);

    % step-like gluing
    sigGl(1:bottomIndx, :) = sigNR(1:bottomIndx, :) ./ sigRatio;

    m = repmat((transpose(bottomIndx:topIndx) - bottomIndx) ./ (topIndx - bottomIndx), ...
            1, size(sigFR, 2));
    sigGl(bottomIndx:topIndx, :) = sigNR(bottomIndx:topIndx, :) ./ sigRatio .* (1 - m) + ...
                                sigFR(bottomIndx:topIndx, :) .* m;

    sigGl(topIndx:end, :) = sigFR(topIndx:end, :);
end

end