function dataz = tcpZscore(datainput, badframes, external_sigma)
% tcpZscore calculates zscore of data while excluding bad frames from being
% involved in calculating either standard deviation or mean. If an external
% standard deviation value is supplied, that value is used instead.

% dataz = tcpZscore(datainput, badframes, external_sigma)
if nargin < 3
    external_sigma = [];
    if nargin < 2
        badframes = [];
    end
end

% Make a copy of the data
datacopy = datainput;

% Remove bad frames
if ~isempty(badframes)
    datacopy(badframes) = [];
end

% Calculate things
mu = nanmean(datacopy);

if isnan(external_sigma) || isempty(external_sigma)
    sigma = nanstd(datacopy);
else
    sigma = external_sigma;
end

% Output
dataz = (datainput - mu) / sigma;
end