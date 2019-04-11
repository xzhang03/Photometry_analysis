%% Initialization
% Channel info
ch1_pulse_ind = 2; % Where to grab wavelength 1's pulse info
ch2_pulse_ind = 9; % Where to grab wavelength 2's pulse info
data_ind = 1; % Where to grab fluorescence info
freq = 50; % Sampling rate after downsampling (i.e., pulse rate of each channel in Hz)

% Channel thresholds (mostly depends on whether digital or analog)
ch1_pulse_thresh = 2;
ch2_pulse_thresh = 0.5;

%% IO
% common path
defaultpath = '\\anastasia\data\photometry';

% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*.mat'));
filename_output = [filename(1:end-4), '_preprocssed.mat'];
load(fullfile(filepath, filename), 'data');


%% Basic channel info
% Grab pulse info
ch1_pulse = data(ch1_pulse_ind,:) > ch1_pulse_thresh;
ch2_pulse = data(ch2_pulse_ind,:) > ch2_pulse_thresh;

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

% Use median fluorescence during each pulse to calculate fluorescence
% values
for i = 1 : n_points
    % Wavelength 1
    ini_ind = ch1_data_table(i,1);
    end_ind = ch1_data_table(i,1) + ch1_data_table(i,3) - 1;
    ch1_data_table(i,2) = median(data(1,ini_ind:end_ind));
    
    % Wavelength 2
    ini_ind = ch2_data_table(i,1);
    end_ind = ch2_data_table(i,1) + ch1_data_table(i,3) - 1;
    ch2_data_table(i,2) = median(data(1,ini_ind:end_ind));
end
%% Plot raw data data
figure(100)

% Plot raw fluorescence data on the left
subplot(1,3,1)
plot((1 : n_points)'/freq, [ch1_data_table(:,2),ch2_data_table(:,2)])
xlabel('Time (s)')
ylabel('Photodiod voltage (V)')

%% Power analysis
% FFT (data, sampling rate, don't plot)
[Powers, fft_freq] = ft2([ch1_data_table(:,2) , ch2_data_table(:,2)] , 50, 0);

% Plot FFT info
subplot(1,3,2)
plot(fft_freq, Powers)
xlim([1, freq/2])
ylabel('Power')
xlabel('Frequency')


%% Low pass filter
% Design a filter kernel
d = fdesign.lowpass('Fp,Fst,Ap,Ast',5,10,0.5,40,100);
Hd = design(d,'equiripple');
fvtool(Hd)

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
clear data timestamps
save(fullfile(filepath, filename));
