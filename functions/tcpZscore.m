function dataz = tcpZscore(datainput, badframes)
% tcpZscore calculates zscore of data while excluding bad frames from being
% involved in calculating either standard deviation or mean
% dataz = tcpZscore(datainput, badframes)

if nargin < 2
    badframes = [];
end

% Make a copy of the data
datacopy = datainput;

% Remove bad frames
if ~isempty(badframes)
    datacopy(badframes) = [];
end

% Calculate things
mu = nanmean(datacopy);
sigma = nanstd(datacopy);

% Output
dataz = (datainput - mu) / sigma;
end