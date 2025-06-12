function checklicks(varargin)

%% Parse inputs
if nargin < 1
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'fpath', '');
addOptional(p, 'defaultpath', 'D:\Shared\photometry');
addOptional(p, 'defaultext', '*.mat');

% Channels
addOptional(p, 'lickchs', 8);
addOptional(p, 'ensurechs', 9);

% Downsample for plotting
addOptional(p, 'downsample', 10);
addOptional(p, 'lickdurs', 20:35);

% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% IO
if isempty(p.fpath)
    [fn, fpath] = uigetfile(fullfile(p.defaultpath, p.defaultext));
    p.fpath = fullfile(fpath, fn);
    [~, fname, ~] = fileparts(fn);
else
    [fpath, fname, ~] = fileparts(p.fpath);
end

% Load
fprintf('Loading... ');
tic;
nidaqdata = load(p.fpath, '-mat');
t = toc;
fprintf('Done. %0.1f s\n', t);

%% Make tables
% licks
lickvec = nidaqdata.data(p.lickchs, :);
ensurevec = nidaqdata.data(p.ensurechs, :);
l = length(lickvec);

% Time points
t = (1:p.downsample:l) / nidaqdata.Fs / 60;

% Tables
licktable = chainfinder(nidaqdata.data(p.lickchs(1), :) > 0.5);

%% Reconstruct lick
% Lick count
lickcount = zeros(ceil(l/p.downsample), 1);
lickcount(ceil(licktable(:,1)/p.downsample)) = 1;
lickcount = cumsum(lickcount);

% Ensure count
ensurecount = cumsum(ensurevec);
ensurecount = ensurecount(1:p.downsample:end);
ensurecount = ensurecount / nidaqdata.Fs;

% Figure
figure('Position', [150 450 1200 500])
subplot(1,3,1)
hplot = plotyy(t, lickcount, t, ensurecount);
hplot(1).YLabel.String = 'Licks';
hplot(2).YLabel.String = 'Ensure time (s)';
xlabel('Time (min)')
title(fname);

subplot(1,3,2)
lickdur = hist(licktable(:,2), p.lickdurs);
plot(p.lickdurs/nidaqdata.Fs*1000, lickdur)
xlabel('Lick duration (ms)')

% Lickrate
subplot(1,3,3)
lickrate = nidaqdata.Fs ./ diff(licktable(:,1));
lickrate = movmean(lickrate, round(size(licktable, 1) * 0.1));
plot(licktable(1:end-1, 1)/nidaqdata.Fs/60, lickrate)
xlabel('Time (min)')
ylabel('Licks/s')

fnout = sprintf('%s_licks.png', fname);
saveas(gcf, fullfile(fpath, fnout));
fnout = sprintf('%s_licks.fig', fname);
saveas(gcf, fullfile(fpath, fnout));
fprintf('Figure saved.\n');
end








