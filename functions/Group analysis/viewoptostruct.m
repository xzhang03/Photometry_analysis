function outputstruct = viewoptostruct(optostruct, varargin)
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
addOptional(p, 'xrange', []);

% Nans and other keep criteria
addOptional(p, 'removenans', true); % Remove nans or not
addOptional(p, 'nantolerance', 0); % Remove trials with more than this fraction of nan data
addOptional(p, 'keepc', {'order',[]}); % Criteria for keeping data (just a 1 x 2 cell)

% Sort by trigger length
addOptional(p, 'sortbytls', false);

% Show motion
addOptional(p, 'showmotion', false);
addOptional(p, 'subtractmotion', false); % Linearly regress out motion trial by trial
addOptional(p, 'subtractdirection', 1); % Direction of subtraction: 1 (positive) or -1 (negative)
addOptional(p, 'motiondelay', 0); % Debug variable. Don't change

% Show licking
addOptional(p, 'showlick', false);
addOptional(p, 'licksmoothwin', 0);
addOptional(p, 'showensure', false);

% Output settings
addOptional(p, 'outputdata', false); % Output data
addOptional(p, 'outputfs', 50); % Output Fs

% Show pre/post triggered data instead
addOptional(p, 'datatype', 'trig'); % Can specify 'pretrig' or 'posttrig' or 'shuffletrig'

% Title
addOptional(p, 'title', '');
addOptional(p, 'savefolder', '');
                                                             
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
    case 'shuffletrig'
        if isempty(p.datasets)
            datamat = cell2mat({optostruct(:).photometry_shuffletrig});
        else
            datamat = cell2mat({optostruct(p.datasets).photometry_shuffletrig});
        end
end

% Flip if needed
if p.flip_signal
    datamat = -datamat;
end

% Number of trials
ntrials = size(datamat, 2);

% Motion mat (only using regulat trig mat)
p.showmotion = p.showmotion & strcmpi(p.datatype, 'trig');
p.subtractmotion = p.subtractmotion & strcmpi(p.datatype, 'trig');
if p.showmotion || p.subtractmotion
    if isempty(p.datasets)
        motionmat = cell2mat({optostruct(:).locomotion});
    else
        motionmat = cell2mat({optostruct(p.datasets).locomotion});
    end
    
    % Apply delay (Debug. This is only an estimate)
    if p.motiondelay > 0
        motionmat =...
            vertcat(motionmat(end - (p.motiondelay-1) : end, :), motionmat(1 : end-p.motiondelay, :));
    end
    
    if p.motiondelay < 0
        motionmat =...
            vertcat(motionmat(-p.motiondelay+1 : end, :), motionmat(1 : -p.motiondelay, :));
    end
end

% Licking mat
if p.showlick
    if isempty(p.datasets)
        lickmat = cell2mat({optostruct(:).lick});
    else
        lickmat = cell2mat({optostruct(p.datasets).lick});
    end
end

% Ensure mat
if p.showensure
    if isempty(p.datasets)
        ensuremat = cell2mat({optostruct(:).ensure});
    else
        ensuremat = cell2mat({optostruct(p.datasets).ensure});
    end
end

% Trigger length
if p.sortbytls
    if isempty(p.datasets)
        tls = cell2mat({optostruct(:).tls});
    else
        tls= cell2mat({optostruct(p.datasets).tls});
    end
end

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
    
    % Update locomotion data
    if p.showmotion || p.subtractmotion
        motionmat = motionmat(:, keepvec > 0);
    end
    
    % Update lick data
    if p.showlick
        lickmat = lickmat(:, keepvec > 0);
    end

    % Update lick data
    if p.showensure
        ensuremat = ensuremat(:, keepvec > 0);
    end
    
    % Update trigger lengths
    if p.sortbytls
        tls = tls(keepvec > 0);
    end

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
    
    % Update locomotion data
    if p.showmotion || p.subtractmotion
        motionmat = motionmat(:, goodtrials);
    end
    
    % Update lick data
    if p.showlick
        lickmat = lickmat(:, goodtrials);
    end

    % Update lick data
    if p.showensure
        ensuremat = ensuremat(:, goodtrials);
    end
    
    % Update trigger lengths
    if p.sortbytls
        tls = tls(goodtrials);
    end

    % *need to update showX*
end

% Datamat to show
if isempty(p.showX)
    datamat2show = datamat;
    if p.showmotion || p.subtractmotion
        motionmat2show = motionmat;
    end
    if p.showlick
        lickmat2show = lickmat;
    end
    if p.showensure
        ensuremat2show = ensuremat;
    end

elseif isscalar(p.showX)
    % If specifying the number of trials
    % Grab X number of trials
    if p.showX < ntrials
        showind = randperm(ntrials, p.showX);
        datamat2show = datamat(:, showind);
        if p.showmotion || p.subtractmotion
            motionmat2show = motionmat(:, showind);
        end
        if p.showlick
            lickmat2show = lickmat(:, showind);
        end
        if p.showensure
            ensuremat2show = ensuremat(:, showind);
        end

        if p.sortbytls
            tls = tls(showind);
        end
    else
        datamat2show = datamat;
    end
else
    % If specifying the exact trial indices
    datamat2show = datamat(:, p.showX);
    if p.showmotion || p.subtractmotion
        motionmat2show = motionmat(:, p.showX);
    end
    if p.showlick
        lickmat2show = lickmat(:, p.showX);
    end
    if p.showensure
        ensuremat2show = ensuremat(:, p.showX);
    end
    if p.sortbytls
        tls = tls(p.showX);
    end
end

%% Regress out motion
if p.subtractmotion
    for i = 1 : size(datamat2show,2)
        % Fit
        if range(motionmat2show(:,i)) > 0
            vd = datamat2show(:,i);
            vm = tcpZscore(motionmat2show(:,i) * p.subtractdirection);
            fitinfo = polyfit(vm(vm >0), vd(vm >0), 1);
        else
            fitinfo = [0 0];
        end
        
        % Subtract
        datamat2show(:,i) = vd - (vm * fitinfo(1) + fitinfo(2));
    end
end
% 
% bads = mean(lickmat2show(500:700,:)) < 0.1;
% d2 = datamat(:,bads);
% d2good = datamat(:,~bads);
% plot(movmean([mean(d2good,2), mean(d2,2)],5))

%% Sort by trigger lengths
if p.sortbytls
    [tls, ki] = sort(tls);
    datamat2show = datamat2show(:, ki);
    if p.showmotion
        motionmat2show = motionmat2show(:,ki);
    end
    if p.showlick
        lickmat2show = lickmat2show(:,ki);
    end
    if p.showensure
        ensuremat2show = ensuremat2show(:,ki);
    end
end

%% Plot
for iplot = 1 : 4
    % Plot
    figure('position',[200+iplot*10 50+iplot*10 600 600],'Renderer','painters');
    
    % 1. Subplot for imagesc
    subplot(p.subplotrows, 1, 2 : p.subplotrows);
    
    % Imagesc
    if iplot == 1
        imagesc(datamat2show');
        colormap(b2r_arbitrary_input(p.heatmaprange(1), p.heatmaprange(2), [1 0 0], [0 0 1], [1 1 1]));
    elseif iplot == 2
        if p.showmotion
            imagesc(motionmat2show');
            colormap(b2r_arbitrary_input(-4, 4, [1 0 0], [0 0 1], [1 1 1]));
        else
            close(gcf);
        end
    elseif iplot == 3
        if p.showlick
            imagesc(lickmat2show');
            colormap(b2r_arbitrary_input(-4, 4, [1 0 0], [0 0 1], [1 1 1]));
        else
            close(gcf);
        end
    elseif iplot == 4
        if p.showensure
            imagesc(ensuremat2show');
            colormap(b2r_arbitrary_input(-4, 4, [1 0 0], [0 0 1], [1 1 1]));
        else
            close(gcf);
        end
    end
    
    xrange = get(gca,'xlim');
    yrange = get(gca, 'ylim');
    xlabel('Time (s)')
    
    % X axis
    Fs = optostruct(1).Fs;
    xcell = get(gca, 'XTickLabel');
    for i = 1 : length(xcell)
        xcell{i} = num2str(str2double(xcell{i}) / Fs);
    end
    set(gca, 'XTickLabel', xcell);
    
    % Add line for stim
    if p.optolength > 0
        hold on
        plot([prew_f prew_f], yrange, ...
            [prew_f + p.optolength, prew_f + p.optolength], yrange, 'Color', [0 0 0 0.5])
        hold off
    elseif p.optolength < 0
        hold on
        for i = 1 : size(datamat, 2)
            yrangetrial = [yrange(1)+(i-1) yrange(1)+i];
            plot([prew_f prew_f], yrangetrial, ...
                [prew_f + tls(i), prew_f + tls(i)], yrangetrial, 'Color', [0 0 0 0.5])
        end
        hold off
    end
    ylabel('Trials (random ordered)')
    if ~isempty(p.xrange)
        xlim(p.xrange * Fs);
    end

    % 2. Subplot for overall average
    subplot(p.subplotrows, 1, 1);
    
    % Plot average data
    if p.usemedian
        trace2plot = nanmedian(datamat2show,2);
    else
        trace2plot = nanmean(datamat2show,2);
    end
    
    plot(trace2plot, 'LineWidth', 2);
    if ~isempty(p.xrange)
        xlim(p.xrange * Fs);
    else
        xlim(xrange)
    end
    set(gca, 'XTickLabel', xcell);
    
    % Y max
    ymax = max(trace2plot);
    ymin = min(trace2plot);
    
    % Y lim
    if isempty(p.yrange)
        ylim([ymin - 0.03 ymax + 0.03])
    else
        ylim(p.yrange);
        ymin = p.yrange(1) + 0.03;
        ymax = p.yrange(2) - 0.03;
    end
    
    % Add an y = 0 line and motion
    hold on
    plot(xrange, [0 0], 'Color', [0 0 0]);
    if ~isempty(p.optolength)
        plot([prew_f prew_f + p.optolength], [ymax ymax],...
            'Color', [1 0 0], 'LineWidth', 2);
    end
    
    % Add motion
    if p.showmotion || p.subtractmotion
        % Calculate
        motionvec = nanmean(motionmat2show,2);
        
        % Normalize
        motionvec = mat2gray(motionvec) * (ymax - ymin) + ymin;
        
        % Plot
        plot(motionvec, 'Color', [0.8 0.8 0.8 0.1], 'LineWidth', 1)
    end
    
    % Add licking
    if p.showlick
        % Calculate
        lickvec = nanmean(lickmat2show,2);
        
        % Normalize
        lickvec = mat2gray(lickvec) * (ymax - ymin) + ymin;
        
        % Smoowth
        if p.licksmoothwin > 0
            lickvec = movmean(lickvec, p.licksmoothwin);
        end
    
        % Plot
        plot(lickvec, 'Color', [0.1 0.6 0.6 0.1], 'LineWidth', 1)
    end

    % Add licking
    if p.showensure
        % Calculate
        ensurevec = nanmean(ensuremat2show,2);
        
        % Normalize
        ensurevec = mat2gray(ensurevec) * (ymax - ymin) + ymin;
        
        % Plot
        plot(ensurevec, 'Color', [0.6 0.1 0.6 0.1], 'LineWidth', 1)
    end
    
    hold off
    if p.flip_signal
        ylabel('-F/F (z)')
    else
        ylabel('F/F (z)')
    end
    
    % Title
    if ~isempty(p.title)
        title(p.title);
    end

    if ~isempty(p.savefolder)
        saveas(gcf, fullfile(p.savefolder, sprintf('%s_%i.fig', p.title, iplot)), 'fig');
        saveas(gcf, fullfile(p.savefolder, sprintf('%s_%i.eps', p.title, iplot)), 'epsc');
    end
end

%% Output data
if p.outputdata
    % Sampling frequency (may move up later)
%     Fs = optostruct(1).Fs;
    
    % number of sweeps
    N_plotted = size(datamat,2);
    dataout = nanmean(datamat,2);
    dataout(:,2) = nanstd(datamat,[],2);
    dataout(:,3) = ones(size(datamat,1),1) * N_plotted;
    
    % Mouse
    if isempty(p.datasets)
        mid = cat(2, optostruct(:).mouseid);
    else
        mid = cat(2, optostruct(p.datasets).mouseid);
    end
    umid = unique(mid);
    datamouse = zeros(size(datamat, 1), length(umid));
    for i = 1 : length(umid)
        datamouse(:,i) = mean(datamat(:, mid == umid(i)), 2);
    end

    if p.showmotion
        motionout = nanmean(motionmat, 2);
        motionout(:,2) = nanstd(motionmat,[],2);
        motionout(:,3) = ones(size(motionmat,1),1) * N_plotted;
        motionmouse = zeros(size(motionmat, 1), length(umid));
        for i = 1 : length(umid)
            motionmouse(:,i) = mean(motionmat(:, mid == umid(i)), 2);
        end
    else
        motionout = [];
        motionmat2show = [];
        motionmouse = [];
    end
    
    if p.showlick
        lickout = nanmean(lickmat, 2);
        lickout(:,2) = nanstd(lickmat,[],2);
        lickout(:,3) = ones(size(lickmat,1),1) * N_plotted;
        lickmouse = zeros(size(lickmat, 1), length(umid));
        for i = 1 : length(umid)
            lickmouse(:,i) = mean(lickmat(:, mid == umid(i)), 2);
        end
    else
        lickout = [];
        lickmat2show = [];
        lickmouse = [];
    end

    if p.showensure
        ensureout = nanmean(ensuremat, 2);
        ensureout(:,2) = nanstd(ensuremat,[],2);
        ensureout(:,3) = ones(size(ensuremat,1),1) * N_plotted;
        ensuremouse = zeros(size(ensuremat, 1), length(umid));
        for i = 1 : length(umid)
            ensuremouse(:,i) = mean(ensuremat(:, mid == umid(i)), 2);
        end
    else
        ensureout = [];
        ensuremat2show = [];
        ensuremouse = [];
    end

    % Adjust output sampling rate if needed
    if Fs ~= p.outputfs
        dataout2 = tcpBin(dataout(:,1), Fs, p.outputfs, 'median');
        dataout2(:,2) = tcpBin(dataout(:,2), Fs, p.outputfs, 'median');
        dataout2(:,3) = tcpBin(dataout(:,3), Fs, p.outputfs, 'median');
        datamouse = tcpBin(datamouse, Fs, p.outputfs, 'mean');

        % Put the variable back
        dataout = dataout2;

        if p.showmotion
            motionout2 = tcpBin(motionout(:,1), Fs, p.outputfs, 'median');
            motionout2(:,2) = tcpBin(motionout(:,2), Fs, p.outputfs, 'median');
            motionout2(:,3) = tcpBin(motionout(:,3), Fs, p.outputfs, 'median');
            motionmouse = tcpBin(motionmouse, Fs, p.outputfs, 'mean');
            motionout = motionout2;
        end
        
        if p.showlick
            lickout2 = tcpBin(lickout(:,1), Fs, p.outputfs, 'median');
            lickout2(:,2) = tcpBin(lickout(:,2), Fs, p.outputfs, 'median');
            lickout2(:,3) = tcpBin(lickout(:,3), Fs, p.outputfs, 'median');
            lickmouse = tcpBin(lickmouse, Fs, p.outputfs, 'mean');
            lickout = lickout2;
        end
        
        if p.showensure
            ensureout2 = tcpBin(ensureout(:,1), Fs, p.outputfs, 'median');
            ensureout2(:,2) = tcpBin(ensureout(:,2), Fs, p.outputfs, 'median');
            ensureout2(:,3) = tcpBin(ensureout(:,3), Fs, p.outputfs, 'median');
            ensuremouse = tcpBin(ensuremouse, Fs, p.outputfs, 'mean');
            ensureout = ensureout2;
        end
    end

    outputstruct = struct('dataout', dataout, 'motionout', motionout, 'lickout', lickout,...
        'ensureout', ensureout, 'datamat2show', datamat2show, 'motionmat2show', motionmat2show,...
        'lickmat2show', lickmat2show, 'ensuremat2show', ensuremat2show, 'datamouse', datamouse,...
        'motionmouse', motionmouse, 'lickmouse', lickmouse, 'ensuremouse', ensuremouse);
end
end