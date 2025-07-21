%% Initialization
% Stephen Zhang 2019/10/20

% Use previous path if exists
if ~exist('filepath', 'var')
    clear
    % common path
    defaultpath = 'D:\Shared\photometry';
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
load(fullfile(filepath, filename), 'freq', 'ch1_data_table', 'Ch1_filtered',...
    'n_points', 'opto_pulse_table', 'tone_pulse_table', 'ensure_pulse_table', 'speedvec', 'lick_pulse_table');

%% GLM remove channel artifacts
% Issue with small NIDAQ 
% Don't use this anymore after switching to picodaq
if isfield(TrigCfg, 'GLM_artifacts')
    if TrigCfg.GLM_artifacts
        % Interpolate method (last resort)
        ch1_data_table = artifact_glm(ch1_data_table, data, TrigCfg.GLM_ch, 9);
        
        % Filter
        % Design a filter kernel
        switch freq
            case 10
                d = designfilt("lowpassfir", 'PassbandFrequency', 4, 'StopbandFrequency', 5, ...
                    'PassbandRipple', 0.1, 'StopbandAttenuation', 40, 'DesignMethod', 'equiripple',...
                    'SampleRate', freq);
            otherwise
                d = designfilt("lowpassfir", 'PassbandFrequency', 8, 'StopbandFrequency', 10, ...
                    'PassbandRipple', 0.1, 'StopbandAttenuation', 40, 'DesignMethod', 'equiripple',...
                    'SampleRate', freq);
        end
        % fvtool(d)

        % Filter data
        Ch1_filtered = filtfilt(d,ch1_data_table(:,2));
    end
else
    TrigCfg.GLM_artifacts = false;
end

%% remove channel artifacts
% Issue with small NIDAQ
% Don't use this anymore after switching to picodaq
if isfield(TrigCfg, 'Remove_artifacts')
    if TrigCfg.Remove_artifacts
        % Interpolate method (last resort)
        datavec_artifactremoved = artifact_interpolate(TrigCfg, data, ch1_data_table);
    end
else
    TrigCfg.Remove_artifacts = false;
    datavec_artifactremoved = Ch1_filtered;
end

%% Window info
% Window info
prew_f = TrigCfg.prew * freq;
postw_f = TrigCfg.postw * freq;
l = prew_f + postw_f + 1;

%% Optopulses
% Replace with tone if needed
useTone = TrigCfg.trigtone;
useLicks = TrigCfg.triglicks;

% Grab the opto pulse info and snap it to the photometry pulses
if useTone
    opto = tone_pulse_table(:,2);
elseif useLicks
    opto = lick_pulse_table(:,2);
else
    opto = opto_pulse_table(:,2);
end
    
% Find bad pulses if needed
if ~isempty(TrigCfg.minpulsewidth)
    % Get all pulses
    pulseinfo = chainfinder(opto>0.5);
    
    % Bad pulses (the pulse is too short)
    badpulses = pulseinfo(pulseinfo(:,2) < TrigCfg.minpulsewidth, :);
    badpulses(:,2) = badpulses(:,1) + badpulses(:,2) - 1;
    
    % Clean up
    for i = 1 : size(badpulses, 1)
        data(TrigCfg.opto_channel, badpulses(i,1) : badpulses(i,2)) = 0; %#ok<SAGROW>
    end
end

% Grab opto onsets
optothresh = max(opto)/2;
opto_ons = chainfinder(opto > optothresh);

% Merge into opto trains
if TrigCfg.merge > 0
    opto_ons = chainmerger(opto_ons, TrigCfg.merge * freq, 1);
end

if TrigCfg.minlength > 0
    opto_ons = opto_ons(opto_ons(:,2) >= (TrigCfg.minlength * freq), :);
end

if TrigCfg.minITI > 0
    opto_ons(:, 3) = opto_ons(:, 1) - TrigCfg.minITI * freq;
    opto_ons(:, 4) = opto_ons(:, 1) - 1;
    opto_ons(:, 5) = opto_ons(:, 1) + opto_ons(:, 2) + 1;
    opto_ons(:, 6) = opto_ons(:, 1) + opto_ons(:, 2) + TrigCfg.minITI * freq;

    for i = 1 : size(opto_ons, 1)
        if opto_ons(i, 3) >= 1
            opto_ons(i, 7) = sum(opto(opto_ons(i, 3):opto_ons(i, 4)));
        else
            opto_ons(i, 7) = 0;
        end
        if opto_ons(i, 6) <= n_points
            opto_ons(i, 8) = sum(opto(opto_ons(i, 5):opto_ons(i, 6)));
        else
            opto_ons(i, 8) = 0;
        end

    end

    opto_ons = opto_ons(opto_ons(:,7)==0 & opto_ons(:,8)==0, :);
end

tls = opto_ons(:,2);
tl = TrigCfg.merge * freq;

% Use onset (default) or offset
if TrigCfg.useoffset
    % Offset
    opto_ons = opto_ons(:,1) + opto_ons(:,2) - 1;
else
    % Onset
    opto_ons = opto_ons(:,1);
end

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
tls = tls(badstims == 0);

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
    exp_fit = [];
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

trigmat_avg_view = trigmat_avg - mean(trigmat_avg(1:TrigCfg.prew * freq));
trigmat_avg_unfilt_view = trigmat_avg_unfilt - mean(trigmat_avg_unfilt(1:TrigCfg.prew * freq));

%% Deal with motion
% Initialize a triggered speed matrix
speedmat = zeros(l, n_optostims);
for i = 1 : n_optostims
    speedmat(:,i) = speedvec(inds(i,1) : inds(i,2));
end

% Calculate the average triggered results
speedmat_avg = mean(speedmat,2);

%% Deal with licking
% Initialize a triggered lick matrix
lickvec = lick_pulse_table(:,2);

lickmat = zeros(l, n_optostims);
for i = 1 : n_optostims
    lickmat(:,i) = lickvec(inds(i,1) : inds(i,2));
end
lickmat_avg = mean(lickmat,2);

%% Plot
figure

subplot(1,2,1)
hold on

plot(-TrigCfg.prew : 1/freq : TrigCfg.postw, trigmat_avg_view)
if TrigCfg.useoffset
    plot([-tl 0]/freq, [mean(trigmat_avg_view), mean(trigmat_avg_view)], 'LineWidth', 5)
else
    plot([0 tl]/freq, [mean(trigmat_avg_view), mean(trigmat_avg_view)], 'LineWidth', 5)
end

% Plot running
if ~isempty(speedmat_avg)
    ylims = get(gca, 'YLim');
    plot(-TrigCfg.prew : 1/freq : TrigCfg.postw,...
        speedmat_avg / max(speedmat_avg) / 5 * max(ylims));
end

% Plot licking
if ~isempty(lickmat_avg)
    plot(-TrigCfg.prew : 1/freq : TrigCfg.postw,...
        lickmat_avg / max(lickmat_avg) / 5 * max(ylims));
end

hold off
xlabel('time (s)')
ylabel('Fluorescence')
title('Filtered')

subplot(1,2,2)
hold on
plot(-TrigCfg.prew : 1/freq : TrigCfg.postw, trigmat_avg_unfilt_view)
if TrigCfg.useoffset
    plot([-tl 0]/freq, [mean(trigmat_avg_unfilt_view), mean(trigmat_avg_unfilt_view)], 'LineWidth', 5)
else
    plot([0 tl]/freq, [mean(trigmat_avg_unfilt_view), mean(trigmat_avg_unfilt_view)], 'LineWidth', 5)
end

% Plot running
if ~isempty(speedmat_avg)
    ylims = get(gca, 'YLim');
    plot(-TrigCfg.prew : 1/freq : TrigCfg.postw,...
        speedmat_avg / max(speedmat_avg) / 5 * max(ylims));
end

% Plot licking
if ~isempty(lickmat_avg)
    plot(-TrigCfg.prew : 1/freq : TrigCfg.postw,...
        lickmat_avg / max(lickmat_avg) / 5 * max(ylims));
end

hold off
xlabel('time (s)')
ylabel('Fluorescence')
title('Unfiltered')

%% Save results
save(fullfile(filepath,filename_output_triggered), 'TrigCfg', 'trigmat',...
    'freq', 'prew_f', 'postw_f', 'l', 'opto_ons', 'inds', 'n_optostims',...
    'trigmat_avg', 'data2use' , 'tl', 'tls', 'opto', 'data2use_unfilt', 'exp_fit',...
    'speedmat', 'speedmat_avg', 'lickmat', 'lickmat_avg', 'useTone',...
    'trigmat_unfilt', 'trigmat_avg_unfilt');