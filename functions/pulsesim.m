function [pulsetrain, antiphasetrain] = pulsesim(l, Fs, on_time, off_time)
% pulsesim generates a pulse train based on l (length in vector length),
% Fs (sampling rate in Hz), on_time (time of on in ms), and off_time (time
% of off in ms). It can also generate a anti-phase phase train with the
% same duty cycle.
% [pulsetrain, antiphasetrain] = pulsesim(l, Fs, on_time, off_time)

% Cycle in ms
cycle_ms = on_time + off_time;

% Cycle in vector length
cycle_vec = cycle_ms / 1000 * Fs;

% Generate time vector
t = (1 : l) / cycle_vec * 2 * pi;

% Generate the pulse train
pulsetrain = square(t, on_time / cycle_ms * 100) >= 0.5;

% Generate anti-phase train by delaying the train by half of a wavelength
antiphasetrain = [pulsetrain(end - round(cycle_vec/2) + 1: end),...
    pulsetrain(1 : end - round(cycle_vec/2))];


end