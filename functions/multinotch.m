function mat_out = multinotch(mat_in, fs, varargin)
% Multiple-notch filter

%% Parse inputs
if nargin < 1
    varargin = {};
end

p = inputParser;

% Region of interest
addOptional(p, 'roi', []); % [startindex, endindex]

% Filter parameters
addOptional(p, 'fcenter', []);
addOptional(p, 'fwidth', 0.1);
addOptional(p, 'powerthreshold', 0.001);
addOptional(p, 'minfreq', 0.8); % Signal below this freq will not be filtered

% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% Select region
if isempty(p.roi)
    % Select where to filter
    vshow = mean(mat_in,2);
    figure
    plot(vshow);
    rv = wait(imrect());
    close gcf
    rv = round(rv(1):rv(1)+rv(3));
else
    rv = p.roi(1):p.roi(2);
end

% Construct
v = mat_in(rv,:);

% Construct filter subject
v2 = v(:);
v3 = v2 - mean(v2);

%% Plot FFT to find center
if isempty(p.fcenter)
    % Get ft2
    p.minfreq = 0.8;
    [P_total,freq] = ft2(v3, fs, 0);
    P_total = P_total(freq >= p.minfreq);
    freq = freq(freq >= p.minfreq);

    % Plot
    figure
    findpeaks(P_total, freq, 'MinPeakProminence', p.powerthreshold);
    [~,p.fcenter] = findpeaks(P_total, freq, 'MinPeakProminence', p.powerthreshold);
    hold on
    P_total_thresh = movmedian(P_total, 4) + p.powerthreshold;
    plot(freq, P_total_thresh);
    hold off
end

%% Filter
for i = 1 : length(p.fcenter)
    d_notch = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1', p.fcenter(i)-p.fwidth,...
        'HalfPowerFrequency2',p.fcenter(i)+p.fwidth, 'DesignMethod','butter','SampleRate', fs);
    v3 = filter(d_notch, v3);
end

%% Return
v3 = v3 + mean(v2);
figure()
plot([v2, v3])
legend({'Pre', 'Post'})

% Return matrix
v4 = reshape(v3, size(v));
mat_out = mat_in;
mat_out(rv,:) = v4;

end