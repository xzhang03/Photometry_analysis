%% Initialization
% Stephen Zhang 2019/10/20

% Use previous path if exists
if ~exist('filepath', 'var')
    clear
    % common path
    defaultpath = '\\anastasia\data\photometry';
else
    defaultpath = filepath;
    keep defaultpath
end

% Use filtered traces that are passed from preprocessing?
TrigCfg.use_filtered = false;

% Where to grab wavelength 1's pulse info
TrigCfg.ch1_pulse_ind = 2; 

% Opto pulses
TrigCfg.opto_channel = 5;

% Window info (seconds before and after pulse onsets)
TrigCfg.prew = 3;
TrigCfg.postw = 28;

% The minimal number of seconds between pulses that are still in the same
% train
TrigCfg.trainlength_threshold = 5;

%% IO
% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*_preprocessed.mat'));
filename_output_triggered = [filename(1:end-4), '_trig.mat'];
load(fullfile(filepath, filename), 'data', 'freq', 'ch1_data_table',...
    'Ch1_filtered', 'n_points');

%% Window info
% WIndow info
prew_f = TrigCfg.prew * freq;
postw_f = TrigCfg.postw * freq;
l = prew_f + postw_f + 1;

%% Optopulses
% Grab the opto pulse info
opto = tcpDatasnapper(data(TrigCfg.opto_channel,:), data(TrigCfg.ch1_pulse_ind,:), 'max', 'pulsetopulse');
opto = opto(1:n_points,:);

% Grab opto onsets
opto_ons = chainfinder(opto(:,2));

% Grab opto inter-stim interval
opto_isi = diff(opto_ons(:,1));
opto_isi = [Inf; opto_isi];

% Determine the actual onsets of trains
opto_ons = opto_ons(opto_isi > TrigCfg.trainlength_threshold * freq);

% See if any of the pulses is too close to the beginning or the end of the
% session
badstims = ((opto_ons - prew_f) <= 0) + ((opto_ons + postw_f) > n_points);
opto_ons(badstims > 0) = [];

% Number of stims
n_optostims = length(opto_ons);

%% Grab the point indices
% Indices
inds = opto_ons * [1 1];
inds(:,1) = inds(:,1) - prew_f;
inds(:,2) = inds(:,2) + postw_f;

% Initialize a triggered matrix
trigmat = zeros(l, n_optostims);
if TrigCfg.use_filtered
    for i = 1 : n_optostims
        trigmat(:,i) = Ch1_filtered(inds(i,1) : inds(i,2));
    end
else
    for i = 1 : n_optostims
        trigmat(:,i) = ch1_data_table(inds(i,1) : inds(i,2), 2);
    end
end

% Calculate the average triggered results
trigmat_avg = mean(trigmat,2);

%% Plot
plot(-TrigCfg.prew : 1/freq : TrigCfg.postw, trigmat_avg)
xlabel('time (s)')
ylabel('Fluorescence')

%% Save  results
save(fullfile(filepath,filename_output_triggered), 'TrigCfg', 'trigmat',...
    'freq', 'prew_f', 'postw_f', 'l', 'opto_ons', 'inds', 'n_optostims',...
    'trigmat_avg')