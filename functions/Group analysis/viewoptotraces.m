function viewoptotraces(datatraces, varargin)
% Viewoptotraces plots traces from the opto results

% Parse input
p  = inputParser;

% Basic variables
addOptional(p, 'datasets', []); % Which datasets to use. Leave blank to keep all data.
addOptional(p, 'usemedian', false); % Plot median instead of mean for the plot
addOptional(p, 'flip_signal', false); % Flip signal

% Signal plotting variables
addOptional(p, 'showprestimregression', true); % Show the regression line of the pre-stim data
addOptional(p, 'yrange', [-2 1]); % Range for y

% Opto plotting variables
addOptional(p, 'optoconfactor', 5); % A number used to connect opto stims
addOptional(p, 'optoelevation', 0.2); % How much above the traces to plot the opto ticks
                                                             
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Grab data matrices
if isempty(p.datasets)
    % Data matrix
    datamat_ON = cell2mat({datatraces(:).photometry_stimON});
    datamat_OFF = cell2mat({datatraces(:).photometry_stimOFF});
    
    % Opto matrix
    optomat_ON = cell2mat({datatraces(:).opto_stimON});
    optomat_OFF = cell2mat({datatraces(:).opto_stimOFF});
else
    % Data matrix
    datamat_ON = cell2mat({datatraces(p.datasets).photometry_stimON});
    datamat_OFF = cell2mat({datatraces(p.datasets).photometry_stimOFF});
    
    % Opto matrix
    optomat_ON = cell2mat({datatraces(p.datasets).opto_stimON});
    optomat_OFF = cell2mat({datatraces(p.datasets).opto_stimOFF});
end

% Flip if needed
if p.flip_signal
    datamat_ON = -datamat_ON;
    datamat_OFF = -datamat_OFF;
end

% Number of trials
ntrials = size(datamat_ON, 2);

% Get the Xs
X_on = (datatraces(1).window_info_ON(1) : datatraces(1).window_info_ON(2))';
X_off = (datatraces(1).window_info_OFF(1) : datatraces(1).window_info_OFF(2))';
    
% Get the Fs
Fs = datatraces(1).Fs;
%% Grab linear regression if needed
if p.showprestimregression
    % Initialize
    regmat_ON = nan(length(datatraces(1).photometry_stimON), ntrials);
    regmat_OFF = nan(length(datatraces(1).photometry_stimOFF), ntrials);
    
    for i = 1 : ntrials
        % Get the indices
        if isempty(p.datasets)
            ind = i;
        else
            ind = p.datasets(i);
        end
        
        % Fill
        regmat_ON(:,i) = X_on * datatraces(ind).prestimfit(1) + ...
            datatraces(ind).prestimfit(2) - datatraces(ind).DC_offset;
        regmat_OFF(:,i) = (X_off + datatraces(ind).optofirstlast(2) -...
            datatraces(ind).optofirstlast(1)) * datatraces(ind).prestimfit(1) + ...
            datatraces(ind).prestimfit(2) - datatraces(ind).DC_offset;
    end
    
    % Flip if needed
    if p.flip_signal
        regmat_ON = -regmat_ON;
        regmat_OFF = -regmat_OFF;
    end
end

%% Get the data to plot

if p.usemedian
    % data
    datavec_ON = nanmedian(datamat_ON, 2);
    datavec_OFF = nanmedian(datamat_OFF, 2);
    
    % regression
    regvec_ON = nanmedian(regmat_ON, 2);
    regvec_OFF = nanmedian(regmat_OFF, 2);
else
    % data
    datavec_ON = nanmean(datamat_ON, 2);
    datavec_OFF = nanmean(datamat_OFF, 2);
    
    % regression
    regvec_ON = mean(regmat_ON, 2);
    regvec_OFF = mean(regmat_OFF, 2);
end

% Opto
optovec_ON = nanmean(optomat_ON, 2);
optovec_OFF = nanmean(optomat_OFF, 2);

% Connect opto pulses
if ~isempty(p.optoconfactor)       
    optovec_ON = imclose(optovec_ON, ones(p.optoconfactor, 1));
    optovec_OFF = imclose(optovec_OFF, ones(p.optoconfactor, 1));
end

% Get opto table
optotable_ON = chainfinder(optovec_ON > 0.2);
optotable_ON(:,2) = optotable_ON(:,1) + optotable_ON(:,2) - 1;
optotable_OFF = chainfinder(optovec_OFF > 0.2);
optotable_OFF(:,2) = optotable_OFF(:,1) + optotable_OFF(:,2) - 1;
%% Plot
% Plot
figure('position',[200 100 1000 600]);

% y range
if p.flip_signal
    yrange = flip(-p.yrange);
else
    yrange = ylim(p.yrange);
end

% x ranges
xrange1 = datatraces(1).window_info_ON/Fs;
xrange2 = datatraces(1).window_info_OFF/Fs;

% 1. Subplot for ON
subplot(2,1,1)

% Plot
plot(X_on/Fs, datavec_ON);

hold on
% opto
for i = 1 : size(optotable_ON, 1)
    % opto height
    yopto = nanmax(datavec_ON(optotable_ON(i,1) : optotable_ON(i,2))) + p.optoelevation;
    
    % Plot
    plot((optotable_ON(i,:) + datatraces(1).window_info_ON(1))/Fs, [yopto yopto], 'Color', [1 0 0], 'LineWidth', 3);
end

% X = 0 line
plot([0 0], yrange, 'k--');
hold off

% Ranges
if ~isempty(p.yrange)
    ylim(yrange);
end
xlim(xrange1);

% Regression
if p.showprestimregression
    hold on
    plot(X_on/Fs, regvec_ON, 'Color', [0 0 0 0.5], 'LineWidth', 2);
    hold off
end

% Labels
ylabel('Fluorescence (z)')
xlabel('Time (s)')
title('Stimulation onset')

% 2. Subplot for OFF
subplot(2,1,2)
plot(X_off/Fs, datavec_OFF);

hold on
% opto
for i = 1 : size(optotable_OFF, 1)
    % opto height
    yopto = nanmax(datavec_OFF(optotable_OFF(i,1) : optotable_OFF(i,2))) + p.optoelevation;
    
    % Plot
    plot((optotable_OFF(i,:) + datatraces(1).window_info_OFF(1))/Fs, [yopto yopto], 'Color', [1 0 0], 'LineWidth', 3);
end

% X = 0 line
plot([0 0], yrange, 'k--');
hold off

% ranges
if ~isempty(p.yrange)
    ylim(yrange);
end
xlim(xrange2);

% Regression
if p.showprestimregression
    hold on
    plot(X_off/Fs, regvec_OFF, 'Color', [0 0 0 0.5], 'LineWidth', 2);
    hold off
end

% Labels
ylabel('Fluorescence (z)')
xlabel('Time (s)')
title('Stimulation offset')
end