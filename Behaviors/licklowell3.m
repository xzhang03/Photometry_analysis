function licklowell3(varargin)
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
addOptional(p, 'optoch', 6);
addOptional(p, 'lickchs', [7 8 9]);
addOptional(p, 'ensurechs', [10 11 12]);
addOptional(p, 'lickct', 3); % Works out to be ~3 pulses per lick

% Mouse table
addOptional(p, 'mousetable', ...
    {'SZ1094', 'SZ1095', 'SZ1096';...
    'SZ1097', 'SZ1098', 'SZ1099'; ...
    'SZ1100', 'SZ1101', 'SZ1102'; ...
    'SZ1103', 'SZ1107', ''});

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
m2 = strcmpi(p.mousetable(:,1), mouse);

% Load
fprintf('Loading... ');
tic;
nidaqdata = load(p.fpath, '-mat');
t = toc;
fprintf('Done. %0.1f s\n', t);

%% Resample
% All channels
fprintf('Resampling... ');
tic;
opto = tcpDatasnapper(nidaqdata.data(p.optoch, :)', nidaqdata.data(p.clockch, :)', 'max', 'pulsetopulse');
lick1 = tcpDatasnapper(nidaqdata.data(p.lickchs(1), :)', opto, 'max', 'pulsetopulse');
lick2 = tcpDatasnapper(nidaqdata.data(p.lickchs(2), :)', opto, 'max', 'pulsetopulse');
lick3 = tcpDatasnapper(nidaqdata.data(p.lickchs(3), :)', opto, 'max', 'pulsetopulse');
ensure1 = tcpDatasnapper(nidaqdata.data(p.ensurechs(1), :)', opto, 'max', 'pulsetopulse');
ensure2 = tcpDatasnapper(nidaqdata.data(p.ensurechs(2), :)', opto, 'max', 'pulsetopulse');
ensure3 = tcpDatasnapper(nidaqdata.data(p.ensurechs(3), :)', opto, 'max', 'pulsetopulse');
t = toc;
fprintf('Done. %0.1f s\n', t);

%% Make tables
% Tables
optotable = chainfinder(opto(:,2)>0.5);
licktable1 = chainfinder(lick1(:,2)>0.5);
licktable2 = chainfinder(lick2(:,2)>0.5);
licktable3 = chainfinder(lick3(:,2)>0.5);
ensuretable1 = chainfinder(ensure1(:,2)>0.5);
ensuretable2 = chainfinder(ensure2(:,2)>0.5);
ensuretable3 = chainfinder(ensure3(:,2)>0.5);

% Dos
do1 = ~isempty(licktable1);
do2 = ~isempty(licktable2);
do3 = ~isempty(licktable3);

% Generate lick counts
if do1
    licktable1(:,2) = round(licktable1(:,2) / p.lickct);
end
if do2
    licktable2(:,2) = round(licktable2(:,2) / p.lickct);
end
if do3
    licktable3(:,2) = round(licktable3(:,2) / p.lickct);
end

% Generate accumulation
if do1
    licktable1(:,3) = cumsum(licktable1(:,2));
    ensuretable1(:,3) = cumsum(ensuretable1(:,2));
end
if do2
    licktable2(:,3) = cumsum(licktable2(:,2));
    ensuretable2(:,3) = cumsum(ensuretable2(:,2));
end
if do3
    licktable3(:,3) = cumsum(licktable3(:,2));
    ensuretable3(:,3) = cumsum(ensuretable3(:,2));
end

% Set times to min
optotable(:,1) = optotable(:,1) / p.fs / 60;
if do1
    licktable1(:,1) = licktable1(:,1) / p.fs / 60;
    ensuretable1(:,1) = ensuretable1(:,1) / p.fs / 60;
end
if do2
    licktable2(:,1) = licktable2(:,1) / p.fs / 60;
    ensuretable2(:,1) = ensuretable2(:,1) / p.fs / 60;
end
if do3
    licktable3(:,1) = licktable3(:,1) / p.fs / 60;
    ensuretable3(:,1) = ensuretable3(:,1) / p.fs / 60;
end

%% Plot
figure('Position', [50 50 1600 600]);

% Mouse 1
if do1
    subplot(1,3,1);
    hold on 
    plot(licktable1(:,1),licktable1(:,3))
    plot(ensuretable1(:,1),ensuretable1(:,3)/4)
    hold off
    title(p.mousetable{m2, 1});
    xlabel('min')
end

% Mouse 2
if do2
    subplot(1,3,2);
    hold on 
    plot(licktable2(:,1),licktable2(:,3))
    plot(ensuretable2(:,1),ensuretable2(:,3)/4)
    hold off
    title(p.mousetable{m2, 2});
    xlabel('min')
end

% Mouse 3
if do3
    subplot(1,3,3);
    hold on 
    plot(licktable3(:,1),licktable3(:,3))
    plot(ensuretable3(:,1),ensuretable3(:,3)/4)
    hold off
    title(p.mousetable{m2, 3});
    xlabel('min')
end
legend({'Licks', 'Ensure'})

fnout = sprintf('%s_lickgroup.png', fname);
saveas(gcf, fullfile(fpath, fnout));
fprintf('Figure saved.\n');

%% Save
savestruct = struct('fn', fn, 'fname', fname, 'ensure1', ensure1, 'ensuretable1', ensuretable1,...
    'ensure2', ensure2, 'ensuretable2', ensuretable2, 'ensure3', ensure3, 'opto', opto,...
    'ensuretable3', ensuretable3, 'lick1', lick1, 'licktable1', licktable1, 'lick2', lick2,...
    'licktable2', licktable2, 'lick3', lick3, 'licktable3', licktable3, 'optotable', optotable,...
    'p', p);
fnoutmat = sprintf('%s_lickgroup.mat', fname);
save(fullfile(fpath, fnoutmat), '-struct', 'savestruct', '-v7.3');
fprintf('Mat saved.\n');

end