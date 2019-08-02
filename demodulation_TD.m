%% Initialization
% Add path
addpath('Demodulation Davidson')

% Channel info
data_channel = 3; % Where is the data
sine_1_channel = 2; % Where is the sine wave collected for Channel 1
sine_2_channel = 2; % Where is the sine wave collected for Channel 2

% demodulation parameters (see contdemodulate.m for documentation)
cfg.demod_BW_F = [0.01 15]; % bandwidth (Hz)
cfg.demod_ripp_db = 0.1; % filter design parameter: bandpass ripple
cfg.demod_atten_db = 50; % filter design parameter: stopband rejection

% normalization parameters (see FP_normalize.m for documenation)
cfg.FPnorm_norm_type = 'fit'; % type of normalization to perform
cfg.FPnorm_control_LP_F = [2 3]; % low-pass filter transition band (Hz)
cfg.FPnorm_dFF_zero_prctile = []; % [] = do not re-zero

% baseline rig fluorescence for each channel with animal not plugged in, 
% in Volts (use [] if you didn't measure this).
cfg.rig_baseline_V = [];

% Reconstruct raw data for demodulation
c_Raw.data = single(zeros(size(data')));
c_Raw.data(:,1) = single(data(data_channel, :))';
c_Raw.data(:,2) = single(data(sine_1_channel, :))';
c_Raw.data(:,3) = single(data(sine_2_channel, :))';

c_Raw.chanlabels = {'Det1', 'Ref1X', 'Ref2X', 'Ref1Y', 'Ref2Y'};
%% Generate orthogonal wave for Ch1 carrier
% Find Channel sine frequency
[p_ch1, freq_ch1] = ft2(data(2,:), Fs, false);
[PKS,LOCS]= findpeaks(p_ch1);
[~, id] = max(PKS);
peakf1 = freq_ch1(LOCS(id));

% Find channel period
per1 = Fs / peakf1;

% Shift Channel sine wave by 90 degrees
off_set1 = round(per1 / 4 * 3);
c_Raw.data(:,4) = [data(sine_1_channel,off_set1:end),...
    data(sine_1_channel,1: (off_set1 - 1))]';

%% Generate orthogonal wave for Ch2 carrier
% Find Channel sine frequency
[p_ch2, freq_ch2] = ft2(data(3,:), Fs, false);
[PKS,LOCS]= findpeaks(p_ch2);
[~, id] = max(PKS);
peakf2 = freq_ch2(LOCS(id));

% Find channel period
per2 = Fs / peakf1;

% Shift Channel sine wave by 90 degrees
off_set2 = round(per2 / 4 * 3);
c_Raw.data(:,5) = [data(sine_2_channel,off_set2:end),...
    data(sine_2_channel,1:(off_set2 - 1))]';

%% Fill in the other parameters
c_Raw.name = 'whatever';
c_Raw.chanvals = [];
c_Raw.samplerate = Fs;
c_Raw.tstart = timestamps(1);
c_Raw.tend = timestamps(end);
c_Raw.datarange = [min(c_Raw.data)', max(c_Raw.data)'];
c_Raw.nbad_start = 0;
c_Raw.nbad_end = 0;
c_Raw.max_tserr = 0; % might not be correct to guess 0
c_Raw.mean_tserr = 0; % might not be correct to guess 0

%% Demodulation
if ~exist('cache', 'var'), cache = mkcache(); end

signal_labels = {'465nm' '405nm'};

fprintf('Demodulating raw photometry signal ...\n');
% Demodulate raw detector signal.
[c_Mag, FP_Ref_F, FP_PSDs, cache] = ...
    contdemodulate(c_Raw, ...
    'nsignals', 2,...
    'signal_labels', signal_labels,...
    'bandwidth_F', cfg.demod_BW_F,...
    'ripp_db', cfg.demod_ripp_db,...
    'atten_db', cfg.demod_atten_db,...
    'cache', cache);
fprintf('-->Done!\n');

%% Plot
% Take the data out
output_data = c_Mag.data;

% Plot demodulated signal
figure(101)
subplot(1,2,1)
plot([output_data(:,1), output_data(:,2)])
xlabel('Sample')
ylabel('Demodulated signal')
title('Frequency+phase based demodulation')

% Plot power spectrum
subplot(1,2,2)
[p1,f] = ft2(output_data(:,1), c_Mag.samplerate);
[p2,~] = ft2(output_data(:,2), c_Mag.samplerate);
figure(101)
plot(f(2:end), [p1(2:end),p2(2:end)]);
title('FT')
xlabel('Freq (Hz)');
ylabel('Power');