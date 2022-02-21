function lickanalysis(varargin)
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
addOptional(p, 'traingap', 5); % in seconds

% Plot
addOptional(p, 'prew', 5); % pre window in seconds
addOptional(p, 'postw', 30); % post window in seconds
addOptional(p, 'downsamplefs', 50); % Downsample fs

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
    [fpath, fname, ext] = fileparts(p.fpath);
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
    buzz = tcpBin(nidaqdata.data(p.channels.Buzz, :), nidaqdata.Fs, p.downsamplefs, 'max', 2);
    lick = tcpBin(nidaqdata.data(p.channels.lick, :), nidaqdata.Fs, p.downsamplefs, 'mean', 2);
    ensure = tcpBin(nidaqdata.data(p.channels.ensure, :), nidaqdata.Fs, p.downsamplefs, 'max', 2);
else
    buzz = nidaqdata.data(p.channels.Buzz, :)';
    lick = nidaqdata.data(p.channels.lick, :)';
    ensure = nidaqdata.data(p.channels.ensure, :)';
end

% Length
l = length(buzz);

%% Find onsets
% Get a list of the actual pulses of interest
trigpulses = chainfinder(buzz >= p.threshold);

if isempty(trigpulses)
    disp('No pulses found.')
    return
end

% Calculate onset and offets
trigpulses(:,2) = trigpulses(:,1) + trigpulses(:,2) - 1;

% In train mode
if p.traingap > 0
    % Get the inter-pulse interval and remove the ones that are shorter
    % than the gap
    trigpulses_keep = diff(trigpulses(:,1)) >= (p.traingap * p.nidaqFs);
    
    % A vector of the first pulses of each train
    trigpulses_first = [true; trigpulses_keep];
    
    % A vector of the last pulses of each train
    trigpulses_last = [trigpulses_keep; true];
    
    % Get the onsets and offsets of each train
    trigpulses = [trigpulses(trigpulses_first, 1), trigpulses(trigpulses_last, 2)];
end

%% Construct matrices
% windows
prew = round(p.nidaqFs * p.prew);
postw = round(p.nidaqFs * p.postw);
inds = [trigpulses(:,1) - prew, trigpulses(:,1) + postw];

% Remove out of bounds
inds(inds(:,1) < 1, :) = [];
inds(inds(:,2) > l, :) = [];
ntrials = size(inds,1);

% indmat
indmat = (1:ntrials)' * (inds(1,1):inds(1,2));
for i = 2 : ntrials
    indmat(i,:) = inds(i,1):inds(i,2);
end

% Matrices
x = (-prew : postw) / p.nidaqFs;
buzzmat = buzz(indmat);
lickmat = lick(indmat);
ensuremat = ensure(indmat);

% Vectors
buzzvec = mean(buzzmat, 1);
lickvec = mean(lickmat, 1);
% ensurevec = mean(ensuremat, 1);

% Normalize matrices for visualization
inc = 1 / ntrials;
ht = inc * 0.8;
maxbuzz = max(buzz);
maxlick = max(lick);
maxensure = max(ensure);

% Normalize and reverse order (First trial on top)
for i = 1 : ntrials
    buzzmat(i,:) = buzzmat(i,:) / maxbuzz * ht + (ntrials - i) * inc;
    lickmat(i,:) = lickmat(i,:) / maxlick * ht + (ntrials - i) * inc;
    ensuremat(i,:) = ensuremat(i,:) / maxensure * ht + (ntrials - i) * inc;
end

%% Plot
% Reverse order so first trial stay on top
buzzmat = buzzmat(ntrials: -1 : 1, :);
lickmat = lickmat(ntrials: -1 : 1, :);
ensuremat = ensuremat(ntrials: -1 : 1, :);

% Make figure
figure
subplot(6,1,1);
plot(x, smooth(lickvec,20), 'Color', [0.8 0.8 0.8]);
hold on
plot(x, buzzvec, 'Color', [0.1 0.4 0.6])
hold off
yticklabels({})
xticklabels({})
title(fname);

subplot(6,1,2:6);
plot(x, lickmat, 'Color', [0.8 0.8 0.8]);
hold on
plot(x, buzzmat, 'Color', [0.1 0.4 0.6]);
plot(x, ensuremat, 'Color', [0.6 0.2 0.1]);
hold off
xlabel('Time (s)')

for i = 1 : ntrials
    text(-p.prew - 2, 0.5* ht + (ntrials - i) * inc, num2str(i))
end

yticklabels({})
xlim([-p.prew p.postw])


fnout = sprintf('%s_lick.png', fname);
saveas(gcf, fullfile(fpath, fnout));
end