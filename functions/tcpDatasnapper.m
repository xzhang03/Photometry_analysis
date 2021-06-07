function pulse_table = tcpDatasnapper(input_vec, input_pulses, method, window)
% tcpDatasnapper snaps a input vector of data to the sampling rate given by a
% pulse train. It is a downsampling method that ensures the fidelity of
% pulse timing. It can perform 'max', 'min', 'mean', 'median' binning
% methods. It can perform the operations only within each pulse 
% ('withinpulses') or any time between pulse onsets ('pulsetopulse').
% pulse_table = tcpDatasnapper(input_vec, input_pulses, method, window)

% Default options
if nargin < 4
    window = 'pulsetopulse';
    if nargin < 3
        method = 'mean';
    end
end

% Get pulse table
pulse_table = chainfinder(input_pulses > 0.5);
n_points = size(pulse_table, 1);

% Rearrange pulse table
pulse_table(:,3) = pulse_table(:,2);
pulse_table(:,2) = nan;

if strcmpi(window, 'pulsetopulse') % pulse to pulse mode
    pulse_table(1 : end-1, 3) = diff(pulse_table(:,1));
    pulse_table(end,3) = length(input_vec) - pulse_table(end,1) + 1;
    % Grab as many points as possible
end

% Loop through
switch method
    case 'mean' % mean method
        for i = 1 : n_points
            pulse_table(i,2) = ...
                mean(input_vec(pulse_table(i,1) :...
                (pulse_table(i,1) + pulse_table(i,3) - 1)));
        end
    case 'median' % median method
        for i = 1 : n_points
            pulse_table(i,2) = ...
                median(input_vec(pulse_table(i,1) :...
                (pulse_table(i,1) + pulse_table(i,3) - 1)));
        end
    case 'max' % max method
        for i = 1 : n_points
            pulse_table(i,2) = ...
                max(input_vec(pulse_table(i,1) :...
                (pulse_table(i,1) + pulse_table(i,3) - 1)));
        end
    case 'min' % min method
        for i = 1 : n_points
            pulse_table(i,2) = ...
                min(input_vec(pulse_table(i,1) :...
                (pulse_table(i,1) + pulse_table(i,3) - 1)));
        end
    case 'sum' % sum method
        for i = 1 : n_points
            pulse_table(i,2) = ...
                sum(input_vec(pulse_table(i,1) :...
                (pulse_table(i,1) + pulse_table(i,3) - 1)));
        end
end


end