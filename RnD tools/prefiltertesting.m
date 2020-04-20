% demodulation parameters (see contdemodulate.m for documentation)
cfg.BW_F = [0.01 15]; % bandwidth (Hz)
cfg.ripp_db = 0.1; % filter design parameter: bandpass ripple
cfg.atten_db = 50; % filter design parameter: stopband rejection
cfg.LPF_repeats = 2; % How many times to run the low-pass filter per sample

testbpfopt = mkfiltopt('name', 'Bandpass',...
                        'filttype', 'bandpass', ...
                        'F', 100 + [-fliplr(cfg.BW_F), cfg.BW_F],...
                        'atten_db', cfg.atten_db,...
                        'ripp_db', cfg.ripp_db,...
                        'Fs', 2500,...
                        'datatype', 'double');
mybpf = mkfilt('filtopt', testbpfopt);         
%%
test = mybpf.dfilt.filter(data(1,:));
data(1,:) = test;

%%
testlpfopt = mkfiltopt('name', 'Lowpass',...
                        'filttype', 'lowpass', ...
                        'F', [8 10],...
                        'atten_db', cfg.atten_db,...
                        'ripp_db', cfg.ripp_db,...
                        'Fs', 50,...
                        'datatype', 'double');
mylpf = mkfilt('filtopt', testlpfopt);         