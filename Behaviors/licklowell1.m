function licklowell1(varargin)
% 3 channel lick analysis for lowell lab

%% Parse inputs
if nargin < 1
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'fpath', '');
addOptional(p, 'defaultpath', '\\anastasia\data\photometry');
addOptional(p, 'defaultext', '*.mat');

% Channels
addOptional(p, 'fs', 30);
addOptional(p, 'clockch', 5);
addOptional(p, 'optoch', []);
addOptional(p, 'lickchs', 6);
addOptional(p, 'ensurechs', 7);
addOptional(p, 'lickct', 27); % Works out to be ~3 pulses per lick

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

% Mouse
m1 = strfind(fname, '-');
mouse = fname(1:m1(1)-1);

% Load
fprintf('Loading... ');
tic;
nidaqdata = load(p.fpath, '-mat');
t = toc;
fprintf('Done. %0.1f s\n', t);

%% Make tables
% Tables
licktable1 = chainfinder(nidaqdata.data(p.lickchs(1), :) > 0.5);
ensuretable1 = chainfinder(nidaqdata.data(p.ensurechs(1), :) > 0.5);

% Generate lick counts
licktable1(:,2) = round(licktable1(:,2) / p.lickct);
ensuretable1(:,2) = ensuretable1(:,2) / nidaqdata.Fs;

% Generate accumulation
licktable1(:,3) = cumsum(licktable1(:,2));
ensuretable1(:,3) = cumsum(ensuretable1(:,2));

% Set times to min
licktable1(:,1) = licktable1(:,1) / nidaqdata.Fs / 60;
ensuretable1(:,1) = ensuretable1(:,1) / nidaqdata.Fs / 60;

%% Plot
figure('Position', [50 50 600 600]);

% Mouse 1
plotyy(licktable1(:,1),licktable1(:,3), ensuretable1(:,1),ensuretable1(:,3))

title(mouse);
xlabel('min')
legend({'Licks', 'Ensure (s)'})

fnout = sprintf('%s_lickgroup.png', fname);
saveas(gcf, fullfile(fpath, fnout));
fprintf('Figure saved.\n');

%% Save
savestruct = struct('fn', fn, 'fname', fname, 'ensuretable1', ensuretable1,...
    'licktable1', licktable1, 'p', p);
fnoutmat = sprintf('%s_lickgroup.mat', fname);
save(fullfile(fpath, fnoutmat), '-struct', 'savestruct', '-v7.3');
fprintf('Mat saved.\n');

end