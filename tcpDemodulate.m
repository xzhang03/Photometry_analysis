%% Initialization
% Demodulation by quadratic method
% Modified by Stephen Zhang from Thomas Davidson's code
% The original code can be found at 
% https://github.com/tjd2002/tjd-shared-code/tree/d110d151202070adbf06ffb3321f6393eb1a0970/matlab

clear

% Add path
addpath('functions')

% Chatty
verbose = false;

% Channel info
data_channel = 1; % Where is the data
sine_1_channel = 2; % Where is the sine wave collected for Channel 1
sine_2_channel = 3; % Where is the sine wave collected for Channel 2

% demodulation parameters 
cfg.BW_F = [10 15]; % Low-pass filter frequency (Hz) [pass, stop]
cfg.ripp_db = 0.1; % filter design parameter: bandpass ripple
cfg.atten_db = 50; % filter design parameter: stopband rejection
cfg.LPF_repeats = 2; % How many times to run the low-pass filter per sample

% Data structure
Demodstruct = struct('SineFreq', [], 'Preds_data', [], 'Preds_Fs', [],...
    'Prefilt_data', [], 'Prefilt_Fs', [], 'c_X', [],...
    'c_XFs', [], 'c_Y', [], 'c_YFs', [], 'c_Mag', []);

%% IO
% common path
defaultpath = '\\anastasia\data\photometry';

% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*nidaq.mat'));
filename_output = [filename(1:end-4), '_demodulated.mat'];
load(fullfile(filepath, filename), 'data', 'timestamps', 'Fs');


% Reorient data matrix
if size(data, 2) > size(data, 1) 
    data2 = data'; 
else
    data2 = data; 
end

%% Analyze sine waves and generate shifted channels

% Channel 1 (attach to the end of the data2 matrix)
[data2(:, end + 1), Demodstruct(1).SineFreq] = ...
    tcpSineShift(data2(:, sine_1_channel), Fs, 1/4);

% Channel 2 (attach to the end of the data2 matrix)
[data2(:, end + 1), Demodstruct(2).SineFreq] = ...
    tcpSineShift(data2(:, sine_2_channel), Fs, 1/4);

%% Pre-downsample
% Downsample raw detector channel as needed (to ~6x the max ref frequency +
% upper sideband, so still oversampled). (Was 3x, but forgot about 2f
% rectification)

% Freq
res_f = 6 *(max(Demodstruct(1).SineFreq, Demodstruct(2).SineFreq)...
    + max(cfg.BW_F)) / Fs;

if res_f < 1
    % Resample
    data2_ds = TDresamp(data2, 'resample', res_f);
    
    % Fill in the structure
    Demodstruct(1).Preds_Fs = res_f * Fs;
    Demodstruct(1).Preds_data = data2_ds(:, data_channel);
    Demodstruct(2).Preds_Fs =  res_f * Fs;
    Demodstruct(2).Preds_data = data2_ds(:, data_channel);
else
    data2_ds = data2;
    
    % Fill in the structure
    Demodstruct(1).Preds_Fs = Fs;
    Demodstruct(1).Preds_data = data2_ds(:, data_channel);
    Demodstruct(2).Preds_Fs = Fs;
    Demodstruct(2).Preds_data = data2_ds(:, data_channel);
end

%% Design filters
% Make filter cache
filtcache = struct('LPopt', [], 'LPfilter', [], 'BPopt', [], 'BPfilter',[]);
filtcache = repmat(filtcache, [2, 1]);


for i = 1 : 2
    % Low-pass filter design parameters (transition band, in Hz)
    filtcache(i).LPopt = mkfiltopt(...
        'name', sprintf('LPF%d', i),...
        'filttype', 'lowpass', ...
        'F', cfg.BW_F,...
        'atten_db', cfg.atten_db,...
        'ripp_db', cfg.ripp_db);

    % Design bandpass filters for each signal to select modulated
    % signal+sidebands (should these be wider?)
    filtcache(i).BPopt = mkfiltopt(... 
        'name', sprintf('BPF%d', i),...
        'filttype', 'bandpass', ...
        'F', Demodstruct(i).SineFreq + [-fliplr(cfg.BW_F), cfg.BW_F],...
        'atten_db', cfg.atten_db,...
        'ripp_db', cfg.ripp_db); 
end

%% Demodulation

fprintf('Demodulating raw photometry signal ...\n');
% Loop through channels
for i = 1 : 2
    % Pre-bandpass-filter
    if  verbose
        disp(['Bandpass filter Channel ', num2str(i)]); 
    end
    [Demodstruct(i).Prefilt_data, filtcache(i).BPfilter, Demodstruct(i).Prefilt_Fs] =...
        TDfilt(Demodstruct(i).Preds_data, 'filt', filtcache(i).BPfilter,...
        'filtopt', filtcache(i).BPopt, 'samplerate', Demodstruct(i).Preds_Fs,...
        'nonlinphaseok', false, 'nodelaycorrect', false, 'autoresample', false);

    % In-phase product detector. pseudocode: X = Det.*RefX (-> LPF)xN;
    if verbose 
        disp(['Calculating phase-locked Channel ', num2str(i)]); 
    end
    [Demodstruct(i).c_X, filtcache(i).LPfilter, Demodstruct(i).c_XFs] = ...
        TDfilt(Demodstruct(i).Prefilt_data .* data2_ds(:,sine_1_channel),...
        'filt', filtcache(i).LPfilter, 'filtopt', filtcache(i).LPopt,...
        'samplerate', Demodstruct(i).Prefilt_Fs, 'nonlinphaseok', false,...
        'nodelaycorrect', false, 'autoresample', true);
    
    % Repeat Low-pass filter if requested
    if cfg.LPF_repeats > 1
        for j = 1 : cfg.LPF_repeats
            [Demodstruct(i).c_X, filtcache(i).LPfilter, Demodstruct(i).c_XFs] = ...
                TDfilt(Demodstruct(i).c_X,...
                'filt', filtcache(i).LPfilter, 'filtopt', filtcache(i).LPopt,...
                'samplerate', Demodstruct(i).c_XFs, 'nonlinphaseok', false,...
                'nodelaycorrect', false, 'autoresample', false);
        end
    end
    
    % In-phase product detector. pseudocode: Y = Det.*RefY (-> LPF)xN;
    if verbose
        disp(['Calculating orthogonal Channel ', num2str(i)]);
    end
    [Demodstruct(i).c_Y, filtcache(i).LPfilter, Demodstruct(i).c_YFs] = ...
        TDfilt(Demodstruct(i).Prefilt_data .* data2_ds(:,end - 2 + i),...
        'filt', filtcache(i).LPfilter, 'filtopt', filtcache(i).LPopt,...
        'samplerate', Demodstruct(i).Prefilt_Fs, 'nonlinphaseok', false,...
        'nodelaycorrect', false, 'autoresample', true);
    
    % Repeat Low-pass filter if requested
    if cfg.LPF_repeats > 1
        for j = 1 : cfg.LPF_repeats
            [Demodstruct(i).c_Y, filtcache(i).LPfilter, Demodstruct(i).c_YFs] = ...
                TDfilt(Demodstruct(i).c_Y,...
                'filt', filtcache(i).LPfilter, 'filtopt', filtcache(i).LPopt,...
                'samplerate', Demodstruct(i).c_YFs, 'nonlinphaseok', false,...
                'nodelaycorrect', false, 'autoresample', false);
        end
    end
    
    % Add the estimates of X & Y in quadrature to recover magnitude R
    if verbose
        disp(['Calculating magnitude of Channel ', num2str(i)]);
    end
    Demodstruct(i).c_Mag = hypot(Demodstruct(i).c_X, Demodstruct(i).c_Y);

end
fprintf('-->Done!\n');

%% Save

save(fullfile(filepath, filename_output), 'data2', 'data_channel',...
    'Demodstruct', 'filtcache', 'Fs', 'sine_1_channel',...
    'sine_2_channel', 'timestamps');
