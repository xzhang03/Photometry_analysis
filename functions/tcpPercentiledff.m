function out = tcpPercentiledff(vec, fps, time_window, percentile)
% tcpPercentiledff Return a dff with the 10th percentile subtracted across
% a default 32-second window. Input data cannot be negative
% out = tcpPercentiledff(vec, fps, time_window, percentile, offset)
% Now deals with nans better

% Default values from Rohan and Christian
% time_window is moving window of X seconds - 
% calculate f0 at time window prior to each frame
if nargin < 3, time_window = 32; end
if nargin < 4, percentile = 10; end

% Get the number of points
nframes = length(vec);

%% Now calculate dFF using axon method
time_window_frame = round(time_window*fps);

if size(vec,1) == 1
    f0 = nan(1, nframes);
else
    f0 = nan(nframes, 1);
end
for i = 1:nframes
    if i <= time_window_frame
        frames = vec(1:time_window_frame);
        f0(i) = prctile(frames, percentile);
    else
        frames = vec(i - time_window_frame:i-1);
        f0(i) = prctile(frames, percentile);
    end
end

% debug
% plot([vec;f0]');

out = (vec - f0)./f0; 
end

