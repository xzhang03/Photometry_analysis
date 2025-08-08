function checklickscond(varargin)

%% Parse inputs
if nargin < 1
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'fpath', '');
addOptional(p, 'defaultpath', 'D:\shared\photometry');
addOptional(p, 'defaultext', '*.mat');

% Channels
addOptional(p, 'lickchs', 8);
addOptional(p, 'ensurechs', 9);
addOptional(p, 'cuechs', 10);

% Cue merging
addOptional(p, 'cuemerge', 2500); % Points to merge for cue. 2500 pts per second

% Windows
addOptional(p, 'prew', 10);
addOptional(p, 'postw', 50);

% Downsample for plotting
addOptional(p, 'downsample', 100);

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
cuevec = nidaqdata.data(p.cuechs,:);

if ~any(nidaqdata.data(p.cuechs,:) > 0)
    fprintf('No cues detected. Switching to pavlovian.\n')
    p.cuechs = p.ensurechs;
    cuevec = nidaqdata.data(p.cuechs,:);
end

% Downsample
lickvec = tcpBin(lickvec', p.downsample, 1, 'max');
ensurevec = tcpBin(ensurevec', p.downsample, 1, 'max');
cuevec = tcpBin(cuevec', p.downsample, 1, 'max');

% Trials
trials = chainfinder(cuevec > 0.5);
trials = chainmerger(trials, round(p.cuemerge/p.downsample));
ntrials = size(trials, 1);

% prew
prew = nidaqdata.Fs/p.downsample * p.prew;
postw = nidaqdata.Fs/p.downsample * p.postw;

% Time points
t = -prew : postw;
l = length(t);

% Tables
inds = trials(:,1) * ones(1, l) + ones(ntrials, 1) * t;
badtrials = inds(:,end) > length(cuevec);
inds = inds(~badtrials,:);
licksmat = lickvec(inds);
ensuremat = ensurevec(inds);

%% Reconstruct lick
figure('Position', [300 250 960 420])
subplot(1,2,1)
imagesc(licksmat);
ylims = ylim();
hold on
plot([prew, prew], ylims, 'r-')
plot([prew+trials(1,2), prew+trials(1,2)], ylims, 'r-')
hold off
ylim(ylims)
title(fname);

subplot(1,2,2)
imagesc(ensuremat);
ylims = ylim();
hold on
plot([prew, prew], ylims, 'r-')
plot([prew+trials(1,2), prew+trials(1,2)], ylims, 'r-')
hold off
ylim(ylims)
title('Ensure');

fnout = sprintf('%s_licks.png', fname);
saveas(gcf, fullfile(fpath, fnout));
fnout = sprintf('%s_licks.fig', fname);
saveas(gcf, fullfile(fpath, fnout));
fprintf('Figure saved.\n');

end








