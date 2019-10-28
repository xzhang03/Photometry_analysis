function viewbhvstruct(bhvstruct, varargin)
% viewbhvstruct views the behavioral structure data (pre-aligned)
% viewbhvstruct(bhvstruct, varargin)

% Parse input
p  = inputParser;

addOptional(p, 'keepc', {}); % Criteria for keeping the data. Leave blank to keep all data.
addOptional(p, 'sortc', ''); % Criteria for sorting the data. Leave blank for no sorting.
addOptional(p, 'sortdir', 'ascend'); % Direction of sorting
addOptional(p, 'datatoplot', {'data_trim', 'ln_data_trim'}); % Default data
                                                             % to plot
addOptional(p, 'linefields', {'data_trimind', 'ln_data_trimind'}); % Fields to add as a line in the plot
addOptional(p, 'subplotrows', 6); % Number of rows for the subplot
addOptional(p, 'heatmaprange', []); % Range for the heatmap
addOptional(p, 'minlinelength', 0.5); % Minimal length of line (in graph units)
addOptional(p, 'showX', []);    % Just show X of the trials in the heatmap. 
                                % The input can also be a vector to show
                                % specifically those trials. Leave blank
                                % to show all data.
                                                             
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Number of datasets
nset = size(bhvstruct, 1);

% Calculate which datasets to keep
keepvec = ones(nset, 1);
nkeepc = size(p.keepc, 1);

% Number of fields to plot
nfieldstoplot = length(p.datatoplot);

% Loop through to update the keep vector
for i = 1 : nkeepc
    
    % Grab the critia
    cri = p.keepc{i,2};
    
    if ~isempty(cri) % Empty means keep everything
        % Using field as a keep option
        % Grab the relevant data
        keepvec_curr = [bhvstruct(:).(p.keepc{i,1})]';

        % Do the comparison
        keepvec_curr = keepvec_curr * ones(1, length(cri)) ==...
            ones(nset, 1) * cri;
        keepvec_curr = sum(keepvec_curr, 2) > 0;

        % Update the keep vector
        keepvec = keepvec .* keepvec_curr;
    end
end

% Grab the sort vector
if ~isempty(p.sortc)
    % Grab the vector to sort and sort it
    sortvec = [bhvstruct(:).(p.sortc)];
    
    % Only keep some of the datasets according to the keeping criteria
    [~, sortvec] = sort(sortvec, p.sortdir);
    
    sortvec = sortvec(keepvec(sortvec) > 0);

    
    
else
    % Keep the original order
    sortvec = 1 : nset;
    
    % Only keep some of the datasets according to the keeping criteria
    sortvec = sortvec(keepvec > 0);
end

% Grab the datastructure
bhvstruct2view = bhvstruct(sortvec);

% Grab the data
data2view = cell(nfieldstoplot, 1);
for i = 1 : nfieldstoplot
    if isfield(bhvstruct, p.datatoplot{i})
        data2view{i} =...
            [bhvstruct2view.(p.datatoplot{i})]'; 
    end
end

% Make a copy of the data for making mean-traces;
data2average = data2view;

% If using the showX option
if ~isempty(p.showX)
    
    if isscalar(p.showX)
        % If specifying the number of trials
        % Grab X number of trials
        showind = randperm(nset, p.showX);
    else
        % If specifying the exact trial indices
        showind = p.showX;
    end
    
    % Apply sort
    [~, trials2keep, ~] = intersect(sortvec,showind, 'stable');
    
    % Only show them
    bhvstruct2view = bhvstruct2view(trials2keep);
    
    for i = 1 : nfieldstoplot
        datatemp = data2view{i};
        data2view{i} = datatemp(trials2keep, :);
    end
end

% Plot
figure('position',[200 350 600 300])

% Loop through
for i = 1 : nfieldstoplot
    % Subplot for imagesc
    subplot(p.subplotrows, nfieldstoplot, (nfieldstoplot + i) :...
        nfieldstoplot : (nfieldstoplot * p.subplotrows));
    
    % Imagesc
    if ~isempty(p.heatmaprange)
        imagesc(data2view{i}, p.heatmaprange);
    else
        imagesc(data2view{i});
    end
    
    xrange = get(gca,'xlim');
    xlabel('Time')
%     set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
    if ~isempty(p.linefields)
        hold on
        for j = 1 : length(bhvstruct2view)
            % Draw line
            if diff(bhvstruct2view(j).(p.linefields{i})) > 0 
                % If there is line length > 0
                plot(bhvstruct2view(j).(p.linefields{i}), [j j], 'r-');
            else
                % If there is line length > 0
                plot(bhvstruct2view(j).(p.linefields{i}) + [0 p.minlinelength],...
                    [j j], 'r-');
            end
        end
        hold off
    end
    
    % Subplot 2
    % Subplot for average data
    subplot(p.subplotrows, nfieldstoplot, i)
    
    % Plot average data
    plot(nanmean(data2average{i},1));
    
    % Add an y = 0 line
    hold on
    plot(xrange, [0 0], 'Color', [0 0 0]);
    hold off
    
    % Align ranges
    xlim(xrange);
	ylim([min(nanmean(data2average{i},1)), max(nanmean(data2average{i},1))]);
    
%     set(gca,'YTickLabel',[]);
    set(gca,'XTickLabel',[]);
end

end