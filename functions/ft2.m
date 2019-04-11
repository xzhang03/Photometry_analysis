function [P_total,freq] = ft2(data, samplingrate, Plot_or_not)
%ft2 applies fast fourier transformation to data and makes a figure. If
%multiple data series are entered, each should be in a different column.
%   [P_total,freq] = ft2(data, samplingrate, Plot_or_not)

if nargin < 3
    Plot_or_not = 1;
    if nargin < 2
        samplingrate = 1;
    end
end

% Make data column first
if size(data,1) == 1
    data = data';
end

% Grab samples
nsamples = size(data,2);
n = size(data,1);

% Initialize consolidated powers
P_total = zeros(floor(n/2)+1, nsamples);

for i = 1 : nsamples
    % Grab fft
    y = fft(data(:,i));
    
    % Grab power
    P2 = abs(y/n);
    P1 = P2(1 : floor(n/2)+1);
    P1(2:end-1) = 2*P1(2 : end-1);
    
    % Consolidate
    P_total(:,i) = P1;
end

% Calculate frequencies
freq = samplingrate*(0:(n/2))/n;

% y0 = fftshift(y);         % shift y values
% freq = (-n/2:n/2-1)*(samplingrate/n); % 0-centered frequency range
% power = abs(y0).^2/n;    % 0-centered power

if Plot_or_not > 0
    figure
    plot(freq,P_total)
    xlabel('Frequency')
    ylabel('Power')
end
end

