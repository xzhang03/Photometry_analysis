%% Initialization
% Stephen Zhang 2019/10/20

% Use previous path if exists
if ~exist('filepath', 'var')
    clear
    % common path
    defaultpath = 'E:\data\photometry';
elseif exist('TrigCfg', 'var')
    defaultpath = filepath;
    keep defaultpath TrigCfg
else
    defaultpath = filepath;
    keep defaultpath
end

% Use UI
hfig = TrigCfg_UI(defaultpath);
waitfor(hfig);

%% IO
% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*.mat'));
if isempty(TrigCfg.suffix)
    filename_output_triggered = [filename(1:end-4), '_trig.mat'];
else
    filename_output_triggered = sprintf('%s_trig_%s.mat', filename(1:end-4), TrigCfg.suffix);
end
load(fullfile(filepath, filename), 'data', 'freq', 'ch1_data_table',...
    'Ch1_filtered', 'n_points', 'opto_pulse_table', 'tone_pulse_table');

%% GLM remove channel artifacts
% Issue with small NIDAQ 
if isfield(TrigCfg, 'GLM_artifacts')
    if TrigCfg.GLM_artifacts
        % Interpolate method (last resort)
        ch1_data_table = artifact_glm(ch1_data_table, data, TrigCfg.GLM_ch, 9);
        
        % Filter
        % Design a filter kernel
        d = fdesign.lowpass('Fp,Fst,Ap,Ast',8,10,0.5,40, freq);
        Hd = design(d,'equiripple');
        % fvtool(Hd)

        % Filter data
        Ch1_filtered = filter(Hd,ch1_data_table(:,2));
    end
else
    TrigCfg.GLM_artifacts = false;
end

%% remove channel artifacts
% Issue with small NIDAQ
if isfield(TrigCfg, 'Remove_artifacts')
    if TrigCfg.Remove_artifacts
        % Interpolate method (last resort)
        datavec_artifactremoved = artifact_interpolate(TrigCfg, data, ch1_data_table);
    end
else
    TrigCfg.Remove_artifacts = false;
end

%% Window info
% Window info
prew_f = TrigCfg.prew * freq;
postw_f = TrigCfg.postw * freq;
l = prew_f + postw_f + 1;

%% Optopulses
% Replace with tone if needed
useTone = TrigCfg.trigtone;

% Grab the opto pulse info and snap it to the photometry pulses
if ~useTone
    opto = opto_pulse_table(:,2);
else
    opto = tone_pulse_table(:,2);
end
    
% Find bad pulses if needed
if ~isempty(TrigCfg.minpulsewidth)
    % Get all pulses
    pulseinfo = chainfinder(opto>0.5);
    
    % Bad pulses
    badpulses = pulseinfo(pulseinfo(:,2) < TrigCfg.minpulsewidth, :);
    badpulses(:,2) = badpulses(:,1) + badpulses(:,2) - 1;
    
    % Clean up
    for i = 1 : size(badpulses, 1)
        data(TrigCfg.opto_channel, badpulses(i,1) : badpulses(i,2)) = 0; %#ok<SAGROW>
    end
end

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
flattenmode = 1;

% Flatten if needed
if TrigCfg.flatten_data
    if TrigCfg.Remove_artifacts
        [data2use, ~, exp_fit, ~] = tcpUIflatten(datavec_artifactremoved, opto, flattenmode);
        data2use_unfilt = datavec_artifactremoved - exp_fit;
    else
        [data2use, ~, exp_fit, ~] = tcpUIflatten(data2use, opto, flattenmode);
        data2use_unfilt = ch1_data_table(:, 2) - exp_fit;
    end
else
    if TrigCfg.Remove_artifacts
        data2use_unfilt = datavec_artifactremoved;
    else
        data2use_unfilt = ch1_data_table(:, 2);
    end
end
plot([data2use, opto])

%% Sliding window dff data
% Dff data if needed
if TrigCfg.dff_data
    % Pull data
    data2use = Ch1_filtered;

    if TrigCfg.Remove_artifacts
        data2use = tcpPercentiledff(datavec_artifactremoved, freq, TrigCfg.dff_win, TrigCfg.dff_prc);
        data2use_unfilt = data2use;
    else
        data2use = tcpPercentiledff(data2use, freq, TrigCfg.dff_win, TrigCfg.dff_prc);
        data2use_unfilt = tcpPercentiledff(ch1_data_table(:, 2), freq, TrigCfg.dff_win, TrigCfg.dff_prc);
    end
    exp_fit = [];
    plot([data2use, opto])
end


%% Grab the point indices
% Indices
inds = opto_ons * [1 1];
inds(:,1) = inds(:,1) - prew_f;
inds(:,2) = inds(:,2) + postw_f;

% Initialize a triggered matrix
trigmat = zeros(l, n_optostims);
trigmat_unfilt = zeros(l, n_optostims);
for i = 1 : n_optostims
    trigmat(:,i) = data2use(inds(i,1) : inds(i,2));
    trigmat_unfilt(:,i) = data2use_unfilt(inds(i,1) : inds(i,2));
end

% Calculate the average triggered results
% trigmat_avg = mean(trigmat(:,end-10:end),2);
trigmat_avg = nanmean(trigmat,2);
trigmat_avg_unfilt = nanmean(trigmat_unfilt, 2);

%% Deal with motion
% Check if the running file is there
runningfn = sprintf('%srunning.mat', filename(1:end-22));
runningfn_full = fullfile(filepath, runningfn);

if exist(runningfn_full, 'file')
    % Load running data
    running = load(runningfn_full, 'speed');
    
    % Running running sample count
    nrunpulse = size(chainfinder(data(TrigCfg.camch,:)>0.5),1);
    nrunlength = length(running.speed);
    if nrunpulse ~= nrunlength
        % Say something
        fprintf('Running digitization is %0.3f%% off\n', (1 - nrunlength/nrunpulse)*100);
        
        % Upsample running data
        speed_upsampled0 = TDresamp(running.speed', 'resample', nrunpulse/nrunlength * 0.9974);
        speed_upsampled = TDresamp(speed_upsampled0, 'resample',...
            n_points/nrunpulse);
    else
        % Upsample running data
        speed_upsampled = TDresamp(running.speed', 'resample',...
            n_points/length(running.speed));
    end
    
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
    
%     imagesc(speedmat')
%     corr([speed_upsampled, Ch1_filtered],'rows','complete')
    
    % Calculate the average triggered results
    speedmat_avg = mean(speedmat,2);
else
    % Store empty speed matrices
    speedmat = [];
    speedmat_avg = [];
end

%% Deal with licking
% Initialize a triggered lick matrix
lickvec = tcpDatasnapper(data(TrigCfg.lickch,:)', data(TrigCfg.ch1_pulse_ind,:)', 'max', 'pulsetopulse');
lickvec = lickvec(:,2);

lickmat = zeros(l, n_optostims);
for i = 1 : n_optostims
    lickmat(:,i) = lickvec(inds(i,1) : inds(i,2));
end
lickmat_avg = mean(lickmat,2);

%% Plot
figure
subplot(1,2,1)
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
title('Filtered')

subplot(1,2,2)
hold on
plot(-TrigCfg.prew : 1/freq : TrigCfg.postw, trigmat_avg_unfilt)
plot([0 tl]/freq, [mean(trigmat_avg_unfilt), mean(trigmat_avg_unfilt)], 'LineWidth', 5)

% Plot running
if ~isempty(speedmat_avg)
    ylims = get(gca, 'YLim');
    plot(-TrigCfg.prew : 1/freq : TrigCfg.postw,...
        speedmat_avg / max(speedmat_avg) * ylims(2));
end

hold off
xlabel('time (s)')
ylabel('Fluorescence')
title('Unfiltered')

%% Save results
if TrigCfg.flatten_data
    save(fullfile(filepath,filename_output_triggered), 'TrigCfg', 'trigmat',...
        'freq', 'prew_f', 'postw_f', 'l', 'opto_ons', 'inds', 'n_optostims',...
        'trigmat_avg', 'data2use' , 'tl', 'opto', 'data2use_unfilt', 'exp_fit',...
        'speedmat', 'speedmat_avg', 'lickmat', 'lickmat_avg', 'useTone',...
        'trigmat_unfilt', 'trigmat_avg_unfilt');
else
    save(fullfile(filepath,filename_output_triggered), 'TrigCfg', 'trigmat',...
        'freq', 'prew_f', 'postw_f', 'l', 'opto_ons', 'inds', 'n_optostims',...
        'trigmat_avg', 'data2use' , 'tl', 'opto', 'data2use_unfilt', ...
        'speedmat', 'speedmat_avg', 'lickmat', 'lickmat_avg', 'useTone',...
        'trigmat_unfilt', 'trigmat_avg_unfilt');
end