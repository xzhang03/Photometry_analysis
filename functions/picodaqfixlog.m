function picodaqfixlog(defaultpath)
% Converts log files into standard photometry mat files. 
% nidaqfixlog(defaultpath)

if nargin < 1
    defaultpath = '\\anastasia\data\photometry\';
end

%% Get config
% Get file
[fn, fp] = uigetfile(fullfile(defaultpath,'.bin'), 'Select the problem bin file.');

% Get a good recording
[fn_config, fp_config] = uigetfile(fullfile(fp,'.mat'), 'Select a good data file of the same experiment type');

% Get the configs
fprintf('Loading config...');
config_loaded = load(fullfile(fp_config, fn_config), 'omniboxsetting', 'Fs', 'frequency', 'configfp', 'channelnames');
fprintf(' Done.\n');

% Read the whole log file in
fprintf('Loading data...');
tic;
fid = fopen(fullfile(fp,fn), 'r');
[dataread, ~] = fread(fid, [6, inf], 'int32');
fclose(fid);
fprintf('Done. %0.1f s.\n', toc);

%% Parse
fda = 8;
nchannels = 4;
ndigitalchannels = 16;

% Get timestamps out
timestamps = dataread(1, :) / config_loaded.frequency;
datad = uint32(dataread(2, :));
dataa = dataread(3:end,:);
n = length(timestamps);

% Initialize
data = zeros((nchannels + ndigitalchannels), n);

% Analog
adivider = 2 ^ 23;
for i = 1 : nchannels
    data(i,:) =  dataa(i,:) / adivider * 1.2 * fda;
end

% Digital
for i = 1 : ndigitalchannels
    data(i+nchannels,:) =  bitget(datad, ndigitalchannels - i + 1);
end

%% Save
% Fill
Fs = config_loaded.Fs;
frequency = config_loaded.frequency;
channelnames = config_loaded.channelnames;
omniboxsetting = config_loaded.omniboxsetting;
configfp = config_loaded.configfp;

% Output file
fn_out = sprintf('%s.mat',fn(1:end-8));

% Save
disp('Saving...');
if ~exist(fullfile(fp,fn_out), 'file') || ...
        input('Nidaq file already exist. Overwrite? (1 = Yes, 0 = No): ') == 1
    
    save(fullfile(fp,fn_out), 'data', 'Fs', 'frequency', 'timestamps', 'channelnames', 'omniboxsetting', 'configfp');
    saved = true;
else
    saved = false;
end
if saved && strcmp(fp(1:2),'\\')
    disp('Done. Data saved to server.')
elseif saved
    disp('Done. Please copy data to server.');
else
    disp('Done. Data did not save.')
end
end