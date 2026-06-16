function [lickcounts, ensurecounts, t] = checklicks3(varargin)

%% Parse inputs
if nargin < 1
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'fpath', '');
addOptional(p, 'defaultpath', 'Z:\photometry');
addOptional(p, 'defaultext', '*.mat');

% Channels
addOptional(p, 'lickchs', [6 7 8]);
addOptional(p, 'ensurechs', [9 10 11]);

% Downsample for plotting
addOptional(p, 'downsample', 10);
addOptional(p, 'downsample2', 100); % For output data
addOptional(p, 'makeplot', true);

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
n = length(p.lickchs);

% Time points
t = (1:p.downsample:l) / nidaqdata.Fs / 60;

% Tables
licktable = cell(n,1);
for i = 1 : n
    licktable{i} = chainfinder(nidaqdata.data(p.lickchs(i), :) > 0.5);
end

%% Reconstruct lick
if p.makeplot
    figure('Position', [150 450 1200 500])
end
newmat = true;
for i = 1 : n
    if isempty(licktable{i})
        lickcounts(:,i) = 0;
        ensurecounts(:,i) = 0;
        continue;
        
    end

    % Lick count
    lickcount = zeros(ceil(l/p.downsample), 1);
    lickcount(ceil(licktable{i}(:,1)/p.downsample)) = 1;
    lickcount = cumsum(lickcount);
    if size(lickcount,1) == 1
        lickcount = lickcount';
    end

    % Ensure count
    ensurecount = cumsum(ensurevec(i,:));
    ensurecount = ensurecount(1:p.downsample:end);
    ensurecount = ensurecount / nidaqdata.Fs;
    if size(ensurecount, 1) == 1
        ensurecount = ensurecount';
    end
    
    % Figure
    if p.makeplot
        subplot(1,3,i)
        hplot = plotyy(t, lickcount, t, ensurecount);
        hplot(1).YLabel.String = 'Licks';
        hplot(2).YLabel.String = 'Ensure time (s)';
        xlabel('Time (min)')
        title(sprintf('%s %i', fname, i));
    end

    % Downsample for output
    lickcount = lickcount(1:p.downsample2:end);
    ensurecount = ensurecount(1:p.downsample2:end);
    
    % Save
    if newmat      
        lickcounts = repmat(lickcount, [1 3]);
        ensurecounts = repmat(ensurecount, [1 3]);
        newmat = false;
    else
        lickcounts(:,i) = lickcount;
        ensurecounts(:,i) = ensurecount;
    end
end

% Downsample t
t = t(1:p.downsample2:end);

end








