function lickplot (varargin)
%% Parse inputs
if nargin < 1
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'fpath', '');
addOptional(p, 'defaultpath', '\\anastasia\data\photometry');
addOptional(p, 'defaultext', '*.mat');

% Trains
addOptional(p, 'threshold', 1); % in voltage

% Plot
addOptional(p, 'makeplot', true); % Make plot
addOptional(p, 'smoothwin', 5); % In seconds
addOptional(p, 'downsamplefs', 50); % Downsample fs

% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

% Debug
p.fpath = '\\anastasia\data\photometry\SZ919\220426_SZ919\SZ919-220426-001-nidaq.mat';

%% IO
if isempty(p.fpath)
    [fn, fpath] = uigetfile(fullfile(p.defaultpath, p.defaultext));
    p.fpath = fullfile(fpath, fn);
    [~, fname, ~] = fileparts(fn);
else
    [fpath, fname, ~] = fileparts(p.fpath);
end

% Load
nidaqdata = load(p.fpath, '-mat');

% Channels
channels = inputParser;
addOptional(channels, 'PD1', 1);
addOptional(channels, 'PD2', []);
addOptional(channels, 'Ch1in', 2);
addOptional(channels, 'camera', 3);
addOptional(channels, 'ensure', 4);
addOptional(channels, 'lick', 6);
addOptional(channels, 'Ch2in', 7);
addOptional(channels, 'Buzz', 8);
addOptional(channels, 'PD2Reserved', []);

if isempty(nidaqdata.channelnames{5})
    nidaqdata.channelnames{5} = 'PD2Reserved'; % Historical
end

parse(channels, nidaqdata.channelnames{:});
channels = channels.Results;
p.channels = channels;

% Fs
if p.downsamplefs ~= nidaqdata.Fs
    p.nidaqFs = p.downsamplefs;
else
    p.nidaqFs = nidaqdata.Fs;
end

%% Downsample
if p.downsamplefs ~= nidaqdata.Fs
    lick = tcpBin(nidaqdata.data(p.channels.lick, :), nidaqdata.Fs, p.downsamplefs, 'mean', 2);
%     ensure = tcpBin(nidaqdata.data(p.channels.ensure, :), nidaqdata.Fs, p.downsamplefs, 'max', 2);
else
    lick = nidaqdata.data(p.channels.lick, :)';
%     ensure = nidaqdata.data(p.channels.ensure, :)';
end

% Length
l = length(lick);
x = 0 : 1/p.nidaqFs : (l-1)/p.nidaqFs;

%% Find lick events
% Chainfinder
lickmat = chainfinder(lick > p.threshold);
lickmat(:,2) = lickmat(:,1) + lickmat(:,2) - 1;
lickmat(1:end-1,3) = p.nidaqFs ./ diff(lickmat(:,1)); 
lickmat(end,3) = lickmat(end-1,3);
nlicks = size(lickmat,1);

% Smooth
lickrate = zeros(l,1);
for i = 1 : nlicks
    lickrate(lickmat(i,1) : lickmat(i,2)) = lickmat(i,3);
end
if ~isempty(p.smoothwin)
    lickrate = movmean(lickrate, p.smoothwin * p.nidaqFs);
end

%% Find lick rate using cdf
% Chainfinder
lickmatcdf = lickmat(:,1);
lickmatcdf(:,2) = 1 : nlicks;
lickmatcdf(nlicks+1,1) = l;
lickmatcdf(nlicks+1,2) = lickmatcdf(nlicks,2);

%% Plot
if p.makeplot
    figure
    [hAx,~,~] = plotyy(x/60, lickrate, lickmatcdf(:,1)/p.nidaqFs/60,lickmatcdf(:,2));
    
    xlabel('Time (min)')

    ylabel(hAx(1),'Smoothed lickrate (lick/s)') % left y-axis 
    ylabel(hAx(2),'Cumulative lick count') % right y-axis
    
    fnout = sprintf('%s_lickplot.png', fname);
    saveas(gcf, fullfile(fpath, fnout));
end

end