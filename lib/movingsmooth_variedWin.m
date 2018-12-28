function [slope] = movingsmooth_variedWin(signal, winWidth)
%MOVINGSMOOTH_VARIEDWIN calculate the derivative with sliding smooth function.
%	Example:
%		[slope] = movingsmooth_variedWin(signal, winWidth)
%	Inputs:
%		signal, winWidth
%	Outputs:
%		slope
%	History:
%		2018-08-07. First edition by Zhenping
%	Contact:
%		zhenping@tropos.de

if nargin < 2
	error('Not enought inputs.');
end

slope = NaN(size(signal));
if isscalar(winWidth)
	slope = diff(smooth([signal(end), signal], winWidth, 'sgolay', 1));
	return
end

if ismatrix(winWidth)
	signal = [signal(end), signal];
	if size(winWidth, 2) == 3
		for iWin = 1:size(winWidth, 1)
            startIndx = max(1, winWidth(iWin, 1) - fix((winWidth(iWin, 3) - 1)/2));
            endIndx = min(length(signal), winWidth(iWin, 2) + fix(winWidth(iWin, 3)/2));
			tmp = diff(smooth(signal(startIndx:endIndx), winWidth(iWin, 3), 'moving'));
            slope(winWidth(iWin, 1):winWidth(iWin, 2)) = tmp((winWidth(iWin, 1) - startIndx + 1):(winWidth(iWin, 2) - startIndx + 1));
		end
	end
end

end