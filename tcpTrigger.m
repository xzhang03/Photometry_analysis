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

% Flatten data
TrigCfg.flatten_data = true;

% Where to grab wavelength 1's pulse info
TrigCfg.ch1_pulse_ind = 2; 

% Opto pulses
TrigCfg.opto_channel = 6;
TrigCfg.minpulsewidth = 5; % Minimal number of data points (in NIDAQ sample rate)
                           % to be considered a real opto pulse (preventing falsely binarized opto data);

% Window info (seconds before and after pulse onsets)
TrigCfg.prew = 8;
TrigCfg.postw = 28;

% The minimal number of seconds between pulses that are still in the same
% train
TrigCfg.trainlength_threshold = 5;

% Debugging variable (do not change)
TrigCfg.DebugMode = false;
if TrigCfg.DebugMode
    TrigCfg.opto_on_offset = 1; % In seconds
end
%% IO
% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*_preprocessed.mat'));
filename_output_triggered = [filename(1:end-4), '_trig.mat'];
load(fullfile(filepath, filename), 'data', 'freq', 'ch1_data_table',...
    'Ch1_filtered', 'n_points');

%% Window info
% Window info
prew_f = TrigCfg.prew * freq;
postw_f = TrigCfg.postw * freq;
l = prew_f + postw_f + 1;

%% Optopulses
% Find bad pulses if needed
if ~isempty(TrigCfg.minpulsewidth)
    % Get all pulses
    pulseinfo = chainfinder(data(TrigCfg.opto_channel,:)>0.5);
    
    % Bad pulses
    badpulses = pulseinfo(pulseinfo(:,2) < TrigCfg.minpulsewidth, :);
    badpulses(:,2) = badpulses(:,1) + badpulses(:,2) - 1;
    
    % Clean up
    for i = 1 : size(badpulses, 1)
        data(TrigCfg.opto_channel, badpulses(i,1) : badpulses(i,2)) = 0; %#ok<SAGROW>
    end
end

% Grab the opto pulse info and snap it to the photometry pulses
opto = tcpDatasnapper(data(TrigCfg.opto_channel,:), data(TrigCfg.ch1_pulse_ind,:), 'max', 'pulsetopulse');
opto = opto(1:n_points, 2);

% Grab opto onsets
opto_ons = chainfinder(opto > 0.5);

% Grab opto inter-stim interval
opto_isi = diff(opto_ons(:,1));
opto_isi = [Inf; opto_isi];

% Train lengths
train_ons = find(opto_isi > TrigCfg.trainlength_threshold * freq);
tl = opto_ons(train_ons(3)-1) - opto_ons(train_ons(2)) + 2;

% Inter-train interval
ITI = opto_ons(train_ons(3)) - opto_ons(train_ons(2));

% Determine the actual onsets of trains
opto_ons = opto_ons(opto_isi > TrigCfg.trainlength_threshold * freq);

% Apply offset in debugging mode
if TrigCfg.DebugMode
    opto_ons = opto_ons + TrigCfg.opto_on_offset * freq;
end

% See if any of the pulses is too close to the beginning or the end of the
% session
badstims = ((opto_ons - prew_f) <= 0) + ((opto_ons + postw_f) > n_points);
opto_ons(badstims > 0) = [];

% Number of stims
n_optostims = length(opto_ons);

%% Flatten data
% Pull data
data2use = Ch1_filtered;

% Flatten if needed
if TrigCfg.flatten_data
    [data2use, ~, exp_fit, ~] = tcpUIflatten(data2use, opto);
    data2use_unfilt = ch1_data_table(:, 2) - exp_fit;
else
    data2use_unfilt = ch1_data_table(:, 2);
end
plot([data2use, opto])

%% Grab the point indices
% Indices
inds = opto_ons * [1 1];
inds(:,1) = inds(:,1) - prew_f;
inds(:,2) = inds(:,2) + postw_f;

% Initialize a triggered matrix
trigmat = zeros(l, n_optostims);
for i = 1 : n_optostims
    trigmat(:,i) = data2use(inds(i,1) : inds(i,2));
end

% Calculate the average triggered results
trigmat_avg = mean(trigmat,2);

%% Deal with motion
% Check if the running file is there
runningfn = sprintf('%srunning.mat', filename(1:end-22));
runningfn_full = fullfile(filepath, runningfn);

if exist(runningfn_full, 'file')
    % Load running data
    running = load(runningfn_full, 'speed');
    
    % Upsample running data
    speed_upsampled = TDresamp(running.speed', 'resample',...
        n_points/length(running.speed));
    
    % Fix the number of points if needed
    if length(speed_upsampled) > n_points
        speed_upsampled = speed_upsampled(1:n_points);
    elseif length(speed_upsampled) < n_points
        speed_upsampled(end:end + n_points - length(speed_upsampled)) = 0;
    end
    
    % Initialize a triggered speed matrix
    speedmat = zeros(l, n_optostims);
    for i = 1 : n_optostims
        speedmat(:,i) = speed_upsampled(inds(i,1) : inds(i,2));
    end

    % Calculate the average triggered results
    speedmat_avg = mean(speedmat,2);
else
    % Store empty speed matrices
    speedmat = [];
    speedmat_avg = [];
end

%% Plot
figure
hold on
plot(-TrigCfg.prew : 1/freq : TrigCfg.postw, trigmat_avg)
plot([0 tl]/freq, [mean(trigmat_avg), mean(trigmat_avg)], 'LineWidth', 5)

% Plot running
if ~isempty(speedmat_avg)
    ylims = get(gca, 'YLim');
    plot(-TrigCfg.prew : 1/freq : TrigCfg.postw,...
        speedmat_avg / max(speedmat_avg) * ylims(2));
end

hold off
xlabel('time (s)')
ylabel('Fluorescence')

%% Save  results
if TrigCfg.flatten_data
    save(fullfile(filepath,filename_output_triggered), 'TrigCfg', 'trigmat',...
        'freq', 'prew_f', 'postw_f', 'l', 'opto_ons', 'inds', 'n_optostims',...
        'trigmat_avg', 'data2use' , 'tl', 'opto', 'data2use_unfilt', 'exp_fit',...
        'speedmat', 'speedmat_avg');
else
    save(fullfile(filepath,filename_output_triggered), 'TrigCfg', 'trigmat',...
        'freq', 'prew_f', 'postw_f', 'l', 'opto_ons', 'inds', 'n_optostims',...
        'trigmat_avg', 'data2use' , 'tl', 'opto', 'data2use_unfilt', ...
        'speedmat', 'speedmat_avg');
end