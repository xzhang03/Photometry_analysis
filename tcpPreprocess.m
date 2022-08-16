%% Initialization
% Stephen Zhang 2019/07/30

% Use previous path if exists
if exist('filepath', 'var')
    defaultpath = filepath;
    keep defaultpath
elseif exist('filepath2', 'var')
    defaultpath = filepath2;
    keep defaultpath
else
    clear
    % common path
    defaultpath = '\\anastasia\data\photometry';
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


%% IO

% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*nidaq.mat'));
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

% Rearrange data
ch1_data_table(:,3) = ch1_data_table(:,2);
ch1_data_table(:,2) = nan;
ch2_data_table(:,3) = ch2_data_table(:,2);
ch2_data_table(:,2) = nan;

% Equalize the pulse numbers of the two wavelenghts
n_points = min(size(ch1_data_table(:,1),1),size(ch1_data_table(:,2),1)) - 1;

% Fix pulse 1 if needed
if size(ch1_data_table,1) > n_points
    ch1_data_table = ch1_data_table(1:n_points, :);
end

% Fix pulse 2 if needed
if size(ch2_data_table,1) > n_points
    ch2_data_table = ch2_data_table(1:n_points, :);
end

%% Notch filters
if use_fnotch_60
    % Apply notch filter to remove 60 Hz noise
    d_notch = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1',...
        fnotch_60(1), 'HalfPowerFrequency2',fnotch_60(2), 'DesignMethod','butter','SampleRate', Fs);
    data_notch = filter(d_notch, data(data_channel,:));
else
    data_notch = data(data_channel,:);
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
    ini_ind = ch2_data_table(i,1) + blackout_window;
    end_ind = ch2_data_table(i,1) + ch2_data_table(i,3) - 1;
    ch2_data_table(i,2) = median(data_notch(ini_ind:end_ind));
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
if OPTO_MODE
    % Grab the pulses
    opto_pulse_table = tcpDatasnapper(data(opto_channel,:),...
        data(ch1_pulse_ind,:), 'max', 'pulsetopulse');
    
    % Sync the number of pulses
    opto_pulse_table = opto_pulse_table(1 : n_points, :);
else
    opto_pulse_table = [];
end

%% Copy opto table from a different experiment (debug)
%{
[optofn, optofp] = uigetfile(fullfile(filepath, '*.mat'));
loaded = load(fullfile(optofp, optofn), 'opto_pulse_table');
opto_pulse_table = ch1_data_table;
opto_pulse_table(:,2) = 0;
opto_pulse_table(:,3) = loaded.opto_pulse_table(2,3);
ptable = chainfinder(loaded.opto_pulse_table(:,2) > 0.5);
for i = 1 : size(ptable,1)
    istart = ptable(i,1);
    iend = ptable(i,1) + ptable(i,2) - 1;
    opto_pulse_table(istart:iend,2) = 1;
end
%}

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
    [Powers, fft_freq] = ft2(ch1_data_table(:,2), 50, 0);
else
    [Powers, fft_freq] = ft2([ch1_data_table(:,2) , ch2_data_table(:,2)] , 50, 0);
end

% Plot FFT info
subplot(1,3,2)
plot(fft_freq, Powers)
xlim([1, freq/2])
ylabel('Power')
xlabel('Frequency')


%% Low pass filter
% Design a filter kernel
d = fdesign.lowpass('Fp,Fst,Ap,Ast',8,10,0.5,40, freq);
Hd = design(d,'equiripple');
% fvtool(Hd)

% Filter data
Ch1_filtered = filter(Hd,ch1_data_table(:,2));
Ch2_filtered = filter(Hd,ch2_data_table(:,2));

% Plot filtered fluorescence data on the right
figure(100)
subplot(1,3,3)
plot((1 : n_points)'/freq, [Ch1_filtered,Ch2_filtered])
xlabel('Time (s)')
ylabel('Photodiod voltage (V)')

%% Save
save(fullfile(filepath, filename_output), 'ch1_data_table', 'ch2_data_table',...
    'data', 'freq', 'Fs', 'n_points', 'PULSE_SIM_MODE', 'OPTO_MODE',...
    'timestamps', 'Ch1_filtered', 'Ch2_filtered', 'opto_pulse_table', 'ppCfg');
