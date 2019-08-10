function [shifted_channel, peakf] = tcpSineShift(data, Fs, shift_phase)
% tcpSineShift artificially shifts a sine wave by a given phase
% [shifted_channel, peakf] = tcpSineShift(data, Fs, shift_phase)
% - shift_phase is expressed as a fraction of cycle (e.g., 1/4 means 90 degree
% shift)

% Find Channel sine frequency
[p_ch1, freq_ch1] = ft2(data, Fs, false);
[PKS,LOCS]= findpeaks(p_ch1);
[~, id] = max(PKS);
peakf = freq_ch1(LOCS(id));

% Find channel period
per = Fs / peakf;

% Shift Channel sine wave by 90 degrees
off_set = round(per * (1 - shift_phase));
shifted_channel = [data(off_set:end);...
    data(1: (off_set - 1))];
end