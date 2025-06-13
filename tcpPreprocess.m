%% Initialization
% Stephen Zhang 2019/07/30

% Use previous path if exists
if exist('filepath', 'var')
    if exist('ppCfg', 'var')
        defaultpath = filepath;
        keep defaultpath ppCfg
    else
        defaultpath = filepath;
        keep defaultpath
    end
elseif exist('filepath2', 'var')
    defaultpath = filepath2;
    keep defaultpath
else
    clear
    % common path
    defaultpath = 'D:\Shared\photometry\';
end

% Use UI
hfig = ppCfg_UI(defaultpath);
waitfor(hfig);

% Parse outcome
OPTO_MODE = ppCfg.OPTO_MODE;
PULSE_SIM_MODE = ppCfg.PULSE_SIM_MODE;
data_channel = ppCfg.data_channel;
data_channel2 = ppCfg.data_channel2;
opto_channel = ppCfg.opto_channel;
ch1_pulse_ind = ppCfg.ch1_pulse_ind;
ch2_pulse_ind = ppCfg.ch2_pulse_ind;
ch1_pulse_thresh = ppCfg.ch1_pulse_thresh;
ch2_pulse_thresh = ppCfg.ch2_pulse_thresh;
filt_stim = ppCfg.filt_stim;
stim_filt_range = ppCfg.stim_filt_range;
use_fnotch_60 = ppCfg.use_fnotch_60;
fnotch_60 = ppCfg.fnotch_60;
blackout_window = ppCfg.blackout_window;
freq = ppCfg.freq;
Ambientpts = ppCfg.Ambientpts;
tone_channel = ppCfg.tone_channel;
lick_channel = ppCfg.lick_channel;
ensure_channel = ppCfg.ensure_channel;
cam_channel = ppCfg.cam_channel;

%% IO
% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath, '*.mat'));
filename_output = [filename(1:end-4), '_preprocessed.mat'];
load(fullfile(filepath, filename), 'data', 'timestamps', 'Fs');


%% Basic channel info and point indices
% Gathering pulses
if PULSE_SIM_MODE
    [ch1_pulse, ch2_pulse] = pulsesim(size(data,2), 2500, 9, 10);
else
    % Grab pulse info
    ch1_pulse = data(ch1_pulse_ind,:) > ch1_pulse_thresh;
    ch2_pulse = data(ch2_pulse_ind,:) > ch2_pulse_thresh;
end

% Find pulse points. This step also defines the sampling rate after
% downsampling (which is the rate of pulses)
ch1_data_table = chainfinder(ch1_pulse);
ch2_data_table = chainfinder(ch2_pulse);
if ~isempty(ch2_data_table)
    doch2 = true;
else
    doch2 = false;
end

% Rearrange data
ch1_data_table(:,3) = ch1_data_table(:,2);
ch1_data_table(:,2) = nan;
if doch2
    ch2_data_table(:,3) = ch2_data_table(:,2);
    ch2_data_table(:,2) = nan;
end

% Equalize the pulse numbers of the two wavelenghts
if doch2
    n_points = min(size(ch1_data_table(:,1),1),size(ch2_data_table(:,2),1)) - 1;
else
    n_points = size(ch1_data_table(:,1),1) - 1;
end

% Fix pulse 1 if needed
if size(ch1_data_table,1) > n_points
    ch1_data_table = ch1_data_table(1:n_points, :);
end

% Fix pulse 2 if needed
if size(ch2_data_table,1) > n_points
    ch2_data_table = ch2_data_table(1:n_points, :);
end

% Check freq
truefreq = Fs / median(diff(ch1_data_table(:,1)));
if truefreq < freq * 0.9 || truefreq > freq * 0.9
    freq = truefreq;
end

%% Notch filters
if use_fnotch_60
    % Apply notch filter to remove 60 Hz noise
    d_notch = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1',...
        fnotch_60(1), 'HalfPowerFrequency2',fnotch_60(2), 'DesignMethod','butter','SampleRate', Fs);
    data_notch = filter(d_notch, data(data_channel,:));

    if data_channel2 ~= data_channel && ch1_pulse_ind ~= ch2_pulse_ind && doch2
        data_notch2 = filter(d_notch, data(data_channel2,:));
    end
else
    data_notch = data(data_channel,:);
    if data_channel2 ~= data_channel && ch1_pulse_ind ~= ch2_pulse_ind && doch2
        data_notch2 = data_notch;
    end
end

% Apply another filter to filter out stim artifacts if needed
if OPTO_MODE
    if filt_stim
        d_notch_stim = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1',...
            stim_filt_range(1), 'HalfPowerFrequency2',stim_filt_range(2),...
            'DesignMethod','butter','SampleRate', Fs);
        data_notch = filter(d_notch_stim, data_notch);
    end
end


%% Grab data points
% Use median fluorescence during each pulse to calculate fluorescence
% values
for i = 1 : n_points
    % Wavelength 1
    ini_ind = ch1_data_table(i,1) + blackout_window;
    end_ind = ch1_data_table(i,1) + ch1_data_table(i,3) - 1;
    ch1_data_table(i,2) = median(data_notch(ini_ind:end_ind));
    
    % Wavelength 2
    if doch2
        ini_ind = ch2_data_table(i,1) + blackout_window;
        end_ind = ch2_data_table(i,1) + ch2_data_table(i,3) - 1;
        if data_channel2 ~= data_channel && ch1_pulse_ind ~= ch2_pulse_ind
            ch2_data_table(i,2) = median(data_notch2(ini_ind:end_ind));
        else
            ch2_data_table(i,2) = median(data_notch(ini_ind:end_ind));
        end
    end
end

% Checknans
if any(isnan(ch1_data_table(:,2)))
    nanind = find(isnan(ch1_data_table(:,2)));
    fprintf('Found %i nan in ch1\n', length(nanind));
    for i = 1 : length(nanind)
        ni = nanind(i);
        ch1_data_table(ni,2) = ch1_data_table(ni-1,2);
    end
end
if doch2 && any(isnan(ch2_data_table(:,2)))
    nanind = find(isnan(ch2_data_table(:,2)));
    fprintf('Found %i nan in ch1\n', length(nanind));
    for i = 1 : length(nanind)
        ni = nanind(i);
        ch2_data_table(ni,2) = ch2_data_table(ni-1,2);
    end
end

%% Ambient-light subtraction
if Ambientpts > 0
    % Initialize matrices
    ch1_amb_table = nan(size(ch1_data_table));
    ch2_amb_table = nan(size(ch2_data_table));
    
    % Get the indices
    ch1_amb_table(:,1) = ch1_data_table(:,1) - Ambientpts;
    ch1_amb_table(:,3) = Ambientpts;
    
    ch2_amb_table(:,1) = ch2_data_table(:,1) - Ambientpts;
    ch2_amb_table(:,3) = Ambientpts;
   
    % Fix out-of-bount indices by taking the next point
    if ch1_amb_table(1,1) < 1
        ch1_amb_table(1,1) = ch1_amb_table(2,1);
    end
    if ch2_amb_table(1,1) < 1
        ch2_amb_table(1,1) = ch2_amb_table(2,1);
    end
    
    % Loop through and take median
    for i = 1 : n_points
        % Wavelength 1
        ini_ind = ch1_amb_table(i,1);
        end_ind = ch1_amb_table(i,1) + ch1_amb_table(i,3) - 1;
        ch1_amb_table(i,2) = median(data_notch(ini_ind:end_ind));

        % Wavelength 2
        ini_ind = ch2_amb_table(i,1);
        end_ind = ch2_amb_table(i,1) + ch2_amb_table(i,3) - 1;
        ch2_amb_table(i,2) = median(data_notch(ini_ind:end_ind));
    end
    
    % Subtract
    ch1_data_table(:,2) = ch1_data_table(:,2) - ch1_amb_table(:,2);
    ch2_data_table(:,2) = ch2_data_table(:,2) - ch2_amb_table(:,2);
end

%% Grab opto pulses
%
if OPTO_MODE
    % Grab the pulses
    opto_pulse_table = tcpDatasnapper(data(opto_channel,:),...
        data(ch1_pulse_ind,:), 'max', 'pulsetopulse');
    
    % Sync the number of pulses
    opto_pulse_table = opto_pulse_table(1 : n_points, :);
else
    opto_pulse_table = [];
end
%}

%% Grab tone pulses
if tone_channel < 99
    % Grab the pulses
    tone_pulse_table = tcpDatasnapper(data(tone_channel,:),...
        data(ch1_pulse_ind,:), 'max', 'pulsetopulse');
    
    % Sync the number of pulses
    tone_pulse_table = tone_pulse_table(1 : n_points, :);
else
    tone_pulse_table = [];
end

%% Grab lick pulses
if lick_channel < 99
    % Grab the pulses
    lick_pulse_table = tcpDatasnapper(data(lick_channel,:),...
        data(ch1_pulse_ind,:), 'max', 'pulsetopulse');
    
    % Sync the number of pulses
    lick_pulse_table = lick_pulse_table(1 : n_points, :);
else
    lick_pulse_table = [];
end

%% Grab ensure pulses
if ensure_channel < 99
    % Grab the pulses
    ensure_pulse_table = tcpDatasnapper(data(ensure_channel,:),...
        data(ch1_pulse_ind,:), 'max', 'pulsetopulse');
    
    % Sync the number of pulses
    ensure_pulse_table = ensure_pulse_table(1 : n_points, :);
else
    ensure_pulse_table = [];
end

%% Grab running
% Grab position vec
ix = strfind(filename, '-nidaq');
rundir = dir(fullfile(filepath, sprintf('%srunning.mat', filename(1:ix))));
position = load(fullfile(rundir.folder, rundir.name), 'position');
position = position.position;

% cam pulse
speedvec = resamplepos(position, data(cam_channel,:), ch1_data_table);

%% Plot raw data data
figure(100)

% Plot raw fluorescence data on the left
subplot(1,3,1)
if OPTO_MODE
    plot((1 : n_points)'/freq, [ch1_data_table(:,2), opto_pulse_table(:,2)])
else
    plot((1 : n_points)'/freq, [ch1_data_table(:,2),ch2_data_table(:,2)])
end
xlabel('Time (s)')
ylabel('Photodiod voltage (V)')

%% Power analysis
% FFT (data, sampling rate, don't plot)
if OPTO_MODE
    [Powers, fft_freq] = ft2(ch1_data_table(2:end,2), freq, 0);
else
    [Powers, fft_freq] = ft2([ch1_data_table(2:end,2) , ch2_data_table(2:end,2)] , freq, 0);
end

% Plot FFT info
subplot(1,3,2)
plot(fft_freq, Powers)
xlim([1, freq/2])
ylabel('Power')
xlabel('Frequency')


%% Low pass filter
% Design a filter kernel
switch freq
    case 10
        d = designfilt("lowpassfir", 'PassbandFrequency', 4, 'StopbandFrequency', 5, ...
            'PassbandRipple', 0.1, 'StopbandAttenuation', 20, 'DesignMethod', 'equiripple',...
            'SampleRate', freq);
    otherwise
        d = designfilt("lowpassfir", 'PassbandFrequency', 8, 'StopbandFrequency', 10, ...
            'PassbandRipple', 0.1, 'StopbandAttenuation', 40, 'DesignMethod', 'equiripple',...
            'SampleRate', freq);
end
% fvtool(Hd)

% Filter data
Ch1_filtered = filtfilt(d,ch1_data_table(:,2));
if doch2
    Ch2_filtered = filtfilt(d,ch2_data_table(:,2));
else
    Ch2_filtered = [];
end

% Plot filtered fluorescence data on the right
figure(100)
subplot(1,3,3)
plot((1 : n_points)'/freq, [Ch1_filtered,Ch2_filtered])
xlabel('Time (s)')
ylabel('Photodiod voltage (V)')

%% Save
save(fullfile(filepath, filename_output), 'ch1_data_table', 'ch2_data_table',...
    'freq', 'Fs', 'n_points', 'PULSE_SIM_MODE', 'OPTO_MODE', 'lick_pulse_table', ...
    'timestamps', 'Ch1_filtered', 'Ch2_filtered', 'opto_pulse_table', 'ppCfg',...
    'ensure_pulse_table', 'tone_pulse_table', 'speedvec');
