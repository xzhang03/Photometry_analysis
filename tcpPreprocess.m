%% Initialization
% Stephen Zhang 2019/07/30

% Use previous path if exists
if ~exist('filepath', 'var')
    clear
    % common path
    defaultpath = '\\anastasia\data\photometry';
else
    defaultpath = filepath;
    keep defaultpath
end


% No pulse info (but pulses are used during photometry)
OPTO_MODE = true;

% No pulse info (and no pulses are used during photometry)
PULSE_SIM_MODE = false;

if  OPTO_MODE
    % Single channel recording
    % Where to grab data
    data_channel = 3;
    opto_channel = 5;
    
    % Channel info
    ch1_pulse_ind = 2; % Where to grab wavelength 1's pulse info
    ch2_pulse_ind = 2; % Where to grab wavelength 2's pulse info

    % Channel thresholds (mostly depends on whether digital or analog)
    ch1_pulse_thresh = 1;
    ch2_pulse_thresh = 0.5;
else
    % Where to grab data
    data_channel = 1;

    % Channel info
    ch1_pulse_ind = 2; % Where to grab wavelength 1's pulse info
    ch2_pulse_ind = 5; % Where to grab wavelength 2's pulse info

    % Channel thresholds (mostly depends on whether digital or analog)
    ch1_pulse_thresh = 2;
    ch2_pulse_thresh = 0.5;
end

% [ Black out points ] This will change the values that come out of your analysis!
blackout_window = 9; % Ignore the first X points within each pulse due to capacitated currents

% Channel and frequency data
data_ind = 1; % Where to grab fluorescence info
freq = 50; % Sampling rate after downsampling (i.e., pulse rate of each channel in Hz)

%% IO

% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*nidaq.mat'));
filename_output = [filename(1:end-4), '_preprocessed.mat'];
load(fullfile(filepath, filename), 'data', 'timestamps', 'Fs');


%% Basic channel info
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

% Apply notch filter to remove 60 Hz noise
d_notch = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1',...
    59, 'HalfPowerFrequency2',61, 'DesignMethod','butter','SampleRate', Fs);
data_notch = filter(d_notch, data(data_channel,:));

% Use median fluorescence during each pulse to calculate fluorescence
% values
for i = 1 : n_points
    % Wavelength 1
    ini_ind = ch1_data_table(i,1) + blackout_window;
    end_ind = ch1_data_table(i,1) + ch1_data_table(i,3) - 1;
    ch1_data_table(i,2) = median(data_notch(ini_ind:end_ind));
    
    % Wavelength 2
    ini_ind = ch2_data_table(i,1) + blackout_window;
    end_ind = ch2_data_table(i,1) + ch1_data_table(i,3) - 1;
    ch2_data_table(i,2) = median(data_notch(ini_ind:end_ind));
end

%% Grab opto pulses
if OPTO_MODE
    % Grab the pulses
    opto_pulse_table = tcpDatasnapper(data(opto_channel,:),...
        data(data_channel,:), 'max', 'pulsetopulse');
    
    % Sync the number of pulses
    opto_pulse_table = opto_pulse_table(1 : n_points, :);
else
    opto_pulse_table = [];
end

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
    'timestamps', 'Ch1_filtered', 'Ch2_filtered', 'opto_pulse_table');
