function [lvec, tvec] = binganalysis(varargin)

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
addOptional(p, 'clockch', 5);
addOptional(p, 'optoch', 6);
% addOptional(p, 'lickch', [7 8 9]);
addOptional(p, 'lickch', [10 11 12]);
% Filter
addOptional(p, 'caplickrate', 50);

% Output
addOptional(p, 'increment', 10); % seconds

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
end

% Load
fprintf('Loading %s... ', fn);
tic;
nidaqdata = load(p.fpath, '-mat');
t = toc;
fprintf('Done. %0.1f s\n', t);

data = nidaqdata.data(p.lickch,:)';
Fs = nidaqdata.Fs;

%% Loop through
% Number of mice
nmice = length(p.lickch);

% Threshold in time
tthresh = Fs / p.caplickrate;

% Time
tmax = nidaqdata.timestamps(end);
tvec = 0 : p.increment : tmax;
ltvec = length(tvec);
lvec = zeros(ltvec, nmice);

for imice = 1 : nmice
    % Find pulses
    licks = chainfinder(data(:,imice) > 0.5);
    
    if isempty(licks)
        continue;
    end
    
    % Consolidate pulses to licks
    dlicks = diff(licks(:,1));
    keep = [1; find(dlicks > tthresh)+1];
    n = size(keep,1);
    
    % Loop through to find licks and lick durations
    truelicks = zeros(n, 2);
    for i = 1 : n
        ind = keep(i);
        truelicks(i,1) = licks(ind,1);

        if i < n
            ind2 = keep(i+1);
        else
            ind2 = size(licks,1);
        end
        truelicks(i,2) = licks(ind2,1) + licks(ind2,2) - truelicks(i,1);
    end
    truelicks = truelicks / Fs;
    
    % Make output
    for i = 1 : ltvec
        lvec(i, imice) = sum(truelicks(:,1) <=  tvec(i));
    end
end

end