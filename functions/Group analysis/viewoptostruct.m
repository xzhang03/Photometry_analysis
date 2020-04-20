function dataout = viewoptostruct(optostruct, varargin)
% View opto structures
% Dataout is a x-by-3 matrix of [mean SEM N].

% Parse input
p  = inputParser;

addOptional(p, 'datasets', []); % Which datasets to use. Leave blank to keep all data.
addOptional(p, 'subplotrows', 6); % Number of rows for the subplot

addOptional(p, 'heatmaprange', [-3, 3]); % Range for the heatmap
addOptional(p, 'flip_signal', false); % Flip signal

addOptional(p, 'showX', []);    % Just show X of the trials in the heatmap. 
                                % The input can also be a vector to show
                                % specifically those trials (not recommended now). Leave blank
                                % to show all data.
addOptional(p, 'optolength', []); % Optolength (train)
addOptional(p, 'usemedian', false); % Plot median instead of mean for the plot
addOptional(p, 'yrange', []); % y range for plotting

% Nans and other keep criteria
addOptional(p, 'removenans', true); % Remove nans or not
addOptional(p, 'nantolerance', 0); % Remove trials with more than this fraction of nan data
addOptional(p, 'keepc', {'order',[]}); % Criteria for keeping data (just a 1 x 2 cell)

% Output settings
addOptional(p, 'outputdata', false); % Output data
addOptional(p, 'outputfs', 50); % Output Fs

% Show pre/post triggered data instead
addOptional(p, 'datatype', 'trig'); % Can specific 'pretrig' or 'posttrig'
                                                             
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Grab a data matrix
switch p.datatype
    case 'trig'
        if isempty(p.datasets)
            datamat = cell2mat({optostruct(:).photometry_trig});
        else
            datamat = cell2mat({optostruct(p.datasets).photometry_trig});
        end
    case 'pretrig'
        if isempty(p.datasets)
            datamat = cell2mat({optostruct(:).photometry_pretrig});
        else
            datamat = cell2mat({optostruct(p.datasets).photometry_pretrig});
        end
    case 'posttrig'
        if isempty(p.datasets)
            datamat = cell2mat({optostruct(:).photometry_posttrig});
        else
            datamat = cell2mat({optostruct(p.datasets).photometry_posttrig});
        end
end

% Flip if needed
if p.flip_signal
    datamat = -datamat;
end

% Number of trials
ntrials = size(datamat, 2);
    
% Keep data as criteria
% (Skip this if we are plotting pre/post-triggered data)
if ~isempty(p.keepc{1,2}) && strcmp(p.datatype, 'trig')
    % Calculate which datasets to keep
    keepvec = ones(ntrials, 1);
    nkeepc = size(p.keepc, 1);
    
    for i = 1 : nkeepc
        if isempty(p.datasets)
            % vector for keeping stuff
            keepvec_curr = cell2mat({optostruct(:).(p.keepc{i,1})})';
        else
            keepvec_curr = cell2mat({optostruct(p.datasets).(p.keepc{i,1})})';
        end

        % Grab the critia
        cri = p.keepc{i,2};

        % Do the comparison
        keepvec_curr = keepvec_curr * ones(1, length(cri)) ==...
            ones(ntrials, 1) * cri;
        keepvec_curr = sum(keepvec_curr, 2) > 0;
        
        % Update keep vector
        keepvec = keepvec .* keepvec_curr;
    end
    
    % Update data
    datamat = datamat(:, keepvec > 0);
    
    % Update Number of trials
    ntrials = size(datamat, 2);
   
    % *need to update showX*
end

% Pre window
prew_f = optostruct(1).window_info(1);

%% Grab a data matrix to show
% Remove nans
if p.removenans
    goodtrials = mean(isnan(datamat),1) >= p.nantolerance;
    datamat = datamat(:, goodtrials);
    
    % *need to update showX*
end

% Datamat to show
if isempty(p.showX)
    datamat2show = datamat;
elseif isscalar(p.showX)
    % If specifying the number of trials
    % Grab X number of trials
    if p.showX < ntrials
        showind = randperm(ntrials, p.showX);
        datamat2show = datamat(:, showind);
    else
        datamat2show = datamat;
    end
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
    trace2plot = nanmedian(datamat,2);
else
    trace2plot = nanmean(datamat,2);
end

plot(trace2plot);
xlim(xrange)

% Y max
ymax = max(trace2plot);
ymin = min(trace2plot);

% Y lim
if isempty(p.yrange)
    ylim([ymin - 0.03 ymax + 0.03])
else
    ylim(p.yrange);
end

% Add an y = 0 line
hold on
plot(xrange, [0 0], 'Color', [0 0 0]);
if ~isempty(p.optolength)
    plot([prew_f prew_f + p.optolength], [ymax ymax],...
        'Color', [1 0 0], 'LineWidth', 2);
end
hold off
if p.flip_signal
    ylabel('-F/F (z)')
else
    ylabel('F/F (z)')
end

%% Output data
if p.outputdata
    % Sampling frequency (may move up later)
    Fs = optostruct(1).Fs;
    
    % number of sweeps
    N_plotted = size(datamat,2);
    dataout = nanmean(datamat,2);
    dataout(:,2) = nanstd(datamat,[],2);
    dataout(:,3) = ones(size(datamat,1),1) * N_plotted;
    
    % Adjust output sampling rate if needed
    if Fs ~= p.outputfs
        dataout2 = tcpBin(dataout(:,1), Fs, p.outputfs, 'median');
        dataout2(:,2) = tcpBin(dataout(:,2), Fs, p.outputfs, 'median');
        dataout2(:,3) = tcpBin(dataout(:,3), Fs, p.outputfs, 'median');
        
        % Put the variable back
        dataout = dataout2;
    end
end
end