function output = licklowell1(varargin)
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
addOptional(p, 'lickct', 27); % Pulse width of a lick


% Output vectors
addOptional(p, 'tint', 10); % Time interval in seconds for output

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

title(fname);
xlabel('min')
legend({'Licks', 'Ensure (s)'})

fnout = sprintf('%s_lickgroup.png', fname);
saveas(gcf, fullfile(fpath, fnout));
fprintf('Figure saved.\n');

%% Output vectors
% Time
tvec = (0 : p.tint/60 : max(licktable1(:,1)))';

% Licks
lvec = interp1(licktable1(:,1), licktable1(:,3), tvec);

% Remove nans
lvec_nanchain = chainfinder(isnan(lvec));
if size(lvec_nanchain,1) > 0
    lvec_nanchain(:,2) = lvec_nanchain(:,2) + lvec_nanchain(:,1) - 1;
    if lvec_nanchain(1,1) == 1
        lvec(lvec_nanchain(1,1):lvec_nanchain(1,2)) = 0;
    end
end
if size(lvec_nanchain,1) > 1
    if lvec_nanchain(end,2) == length(lvec)
        lvec(lvec_nanchain(end,1):lvec_nanchain(end,2)) = envec(lvec_nanchain(end,1) - 1);
    end
end

% Ensure
envec = interp1(ensuretable1(:,1), ensuretable1(:,3), tvec);

% Remove nans
envec_nanchain = chainfinder(isnan(envec));
if size(lvec_nanchain,1) > 0
    envec_nanchain(:,2) = envec_nanchain(:,2) + envec_nanchain(:,1) - 1;
    if envec_nanchain(1,1) == 1
        envec(envec_nanchain(1,1):envec_nanchain(1,2)) = 0;
    end
end
if size(lvec_nanchain,1) > 1
    if envec_nanchain(end,2) == length(envec)
        envec(envec_nanchain(end,1):envec_nanchain(end,2)) = envec(envec_nanchain(end,1) - 1);
    end
end
output = [tvec, lvec, envec];

%% Save
savestruct = struct('fn', fn, 'fname', fname, 'ensuretable1', ensuretable1,...
    'licktable1', licktable1, 'p', p, 'tvec', tvec, 'lvec', lvec, 'envec', envec);
fnoutmat = sprintf('%s_lickgroup.mat', fname);
save(fullfile(fpath, fnoutmat), '-struct', 'savestruct', '-v7.3');
fprintf('Mat saved.\n');

end