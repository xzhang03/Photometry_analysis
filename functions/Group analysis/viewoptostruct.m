function viewoptostruct(optostruct, varargin)
% View opto structures

% Parse input
p  = inputParser;

addOptional(p, 'datasets', []); % Which datasets to use. Leave blank to keep all data.
addOptional(p, 'subplotrows', 6); % Number of rows for the subplot

addOptional(p, 'heatmaprange', [-3, 3]); % Range for the heatmap
addOptional(p, 'flip_signal', false); % Flip signal

addOptional(p, 'showX', []);    % Just show X of the trials in the heatmap. 
                                % The input can also be a vector to show
                                % specifically those trials. Leave blank
                                % to show all data.
addOptional(p, 'optolength', []); % Optolength (train)
addOptional(p, 'usemedian', false); % Plot median instead of mean for the plot
                                                             
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Grab a data matrix
if isempty(p.datasets)
    datamat = cell2mat({optostruct(:).photometry_trig});
else
    datamat = cell2mat({optostruct(p.datasets).photometry_trig});
end

% Flip if needed
if p.flip_signal
    datamat = -datamat;
end

% Number of trials
ntrials = size(datamat, 2);

% Pre window
prew_f = optostruct(1).window_info(1);

%% Grab a data matrix to show
% Datamat to show
if isempty(p.showX)
    datamat2show = datamat;
elseif isscalar(p.showX)
    % If specifying the number of trials
    % Grab X number of trials
    showind = randperm(ntrials, p.showX);
    datamat2show = datamat(:, showind);
else
    % If specifying the exact trial indices
    datamat2show = datamat(:, p.showX);
end

%% Plot
% Plot
figure('position',[200 50 600 600]);

% 1. Subplot for imagesc
subplot(p.subplotrows, 1, 2 : p.subplotrows);

% Imagesc
imagesc(datamat2show');
colormap(b2r_arbitrary_input(p.heatmaprange(1), p.heatmaprange(2), [1 0 0], [0 0 1], [1 1 1]));

xrange = get(gca,'xlim');
yrange = get(gca, 'ylim');
xlabel('Time')

% Add line for stim
hold on
plot([prew_f prew_f], yrange, ...
    [prew_f + p.optolength, prew_f + p.optolength], yrange, 'Color', [0 0 0 0.5])
hold off
ylabel('Trials (random ordered)')

% 2. Subplot for overall average
subplot(p.subplotrows, 1, 1);

% Plot average data
if p.usemedian
    trace2plot = median(datamat,2);
else
    trace2plot = mean(datamat,2);
end

plot(trace2plot);
xlim(xrange)

% Y max
ymax = max(trace2plot);

% Y lim
ylim([-0.03 ymax + 0.03])

% Add an y = 0 line
hold on
plot(xrange, [0 0], 'Color', [0 0 0]);
if ~isempty(p.optolength)
    plot([prew_f prew_f + p.optolength], [ymax ymax],...
        'Color', [1 0 0], 'LineWidth', 2);
end
hold off
ylabel('-F/F (z)')
end