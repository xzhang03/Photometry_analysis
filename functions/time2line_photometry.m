function time2line_photometry(datastruct, index, varargin)
% time2line_photometry makes plots that combine both photometry and
% behavior data

if nargin < 2
    % Default plot the first dataset
    index = 1;
end


p = inputParser;

addOptional(p, 'bhvfield', ''); % Which behavior to look at

% Plottting parameters
addOptional(p, 'minlength', 0.2); % Minimal length along the x-axis. In axis units
addOptional(p, 'bhvlinewidth', 3); % Width of behavior lines
addOptional(p, 'Color', [0 0 0]); % Color of the behavioral line
addOptional(p, 'badpoints', 100); % First X points are not used for scaling
addOptional(p, 'yoffset', 0.05); % How much above or below the max photometry 
                               % value are the behavioral lines
addOptional(p, 'yblankspace', 0.2); % how much above or below the 
                                    % photometry traces to draw the box
                               
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Fix color if needed
if ischar(p.Color)
    if length(p.Color) == 6 % String for color
        p.Color = colorconv(p.Color);
    end    
end

%% Grabbing the relevant data
photometry_data = datastruct(index).photometry;
Fs = datastruct(index).Fs;
l = length(photometry_data);
bhv_data = datastruct(index).(p.bhvfield);

% Y location of the behavior line
yrange = [min(photometry_data(p.badpoints : end)) - p.yblankspace,...
    max(photometry_data(p.badpoints : end)) + p.yblankspace];

% Grab events
events = chainfinder(bhv_data > 0.5);
events(:, 2) = events(:, 1) + events(:, 2) - 1;
nevents = size(events, 1);

%% Plot
% Make the plot
figure('Color', [1 1 1]);

% Photometry
plot((1:l)/Fs, photometry_data);
title(sprintf('%s, Sample: %i', p.bhvfield, index));

hold on
% Plot the behavioral lines
for i = 1 : nevents
    % X locations
    x1 = events(i, 1) / Fs;
    x2 = max(events(i, 2)/Fs, events(i,1)/Fs + p.minlength);
    
    % y location
    y = max(photometry_data(events(i,1) : events(i,2))) + p.yoffset;
    
    plot([x1, x2], [y, y], '-',...
            'LineWidth', p.bhvlinewidth, 'Color', p.Color);
end
hold off

% Aspect ratio
pbaspect([6 1 1])
ylim(yrange);
xlabel('Time (s)','FontSize',14)
ylabel('Fluorescence (z)','FontSize',14)
set(gca,'FontSize',14)