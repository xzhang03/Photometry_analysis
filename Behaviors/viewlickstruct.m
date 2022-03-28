function outputstruct = viewlickstruct(datacell, varargin)
% View lick data
%% Parse inputs
if nargin < 2
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'labels', {});
addOptional(p, 'trimwin', []); % Trials beyond here are removed, less than this are getting patted with nans
addOptional(p, 'smoothwin', 5); % In trials

% Plot
addOptional(p, 'pos', [150 550 1600 300]);

% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% Clean up
% Number
nset = length(datacell);

% Labels
if isempty(p.labels)
    p.labels = cell(nset, 1);
    for i = 1 : nset
        p.labels{i} = sprintf('Dataset %i', i);
    end
end

% Trim
if isempty(p.trimwin)
    lvec = [datacell{1}.ntrials];
    p.trimwin = mode(lvec);
end

%% Consolidate data
% Initialize
trigcell = cell(nset, 1);
consumecell = cell(nset, 1);
succcell = cell(nset, 1);
lcell = cell(nset,1);

for ii = 1 : nset
    % Initialize matrix
    l = length(datacell{ii});
    trigmat = nan(p.trimwin, l);
    consumemat = nan(p.trimwin, l);
    succmat = nan(p.trimwin, l);
    
    for i = 1 : l
        % Get n
        n = datacell{ii}(i).ntrials;
        n = min(n, p.trimwin);
        
        % Load
        trigmat(1:n, i) = datacell{ii}(i).triglick(1:n);
        consumemat(1:n, i) = datacell{ii}(i).consumelick(1:n);
        succmat(1:n, i) = datacell{ii}(i).success(1:n);
    end
    
    trigcell{ii} = trigmat;
    consumecell{ii} = consumemat;
    succcell{ii} = succmat;
    lcell{ii} = l;
end

%% Make output
% Initialize
outputstruct = struct('label', '', 'trigout', [], 'trigmeans', [], 'consumeout', [],...
    'consumemeans', [], 'succout', [], 'succmeans', [], 'n', []);
outputstruct = repmat(outputstruct, [nset 1]);

for ii = 1 : nset
    % Initialize
    n = lcell{ii};
    trigout = zeros(p.trimwin, 3);
    consumeout = zeros(p.trimwin, 3);
    succout = zeros(p.trimwin, 3);
    
    % Calculate
    trigout(:,1) = nanmean(trigcell{ii}, 2);
    trigout(:,2) = nanstd(trigcell{ii}, 0, 2);
    trigout(:,3) = n;
    
    consumeout(:,1) = nanmean(consumecell{ii}, 2);
    consumeout(:,2) = nanstd(consumecell{ii}, 0, 2);
    consumeout(:,3) = n;
    
    succout(:,1) = nanmean(succcell{ii}, 2);
    succout(:,2) = nanstd(succcell{ii}, 0, 2);
    succout(:,3) = n;
    
    % Load results into output
    outputstruct(ii).label = p.labels{ii};
    outputstruct(ii).trigout = trigout;
    outputstruct(ii).trigmeans = nanmean(trigcell{ii}, 1)';
    outputstruct(ii).consumeout = consumeout;
    outputstruct(ii).consumemeans = nanmean(consumecell{ii}, 1)';
    outputstruct(ii).succout = succout;
    outputstruct(ii).succmeans = nanmean(succcell{ii}, 1)';
    outputstruct(ii).n = n;
end

%% Make plot
figure('position', p.pos)

% 1. Trig lick vector
subplot(1,6,1)
hold on
for ii = 1 : nset
    plot(movmean(outputstruct(ii).trigout(:,1), p.smoothwin));
end
hold off
xlabel('Trials')
ylabel('Licks/s')
title('Trigger window')
legend(p.labels)

% 2. Trig lick bar
subplot(1,6,2)
hold on
for ii = 1 : nset
    plot(ones(outputstruct(ii).n,1) * ii, outputstruct(ii).trigmeans, '.');
    line([ii-0.3 ii+0.3], mean(outputstruct(ii).trigmeans) * [1 1], 'LineWidth', 3);
end
hold off
set(gca, 'XTick', 1 : nset);
set(gca, 'XTickLabel', p.labels);
ylabel('Licks/s')
title('Trigger window')

% 3. Trig lick vector
subplot(1,6,3)
hold on
for ii = 1 : nset
    plot(movmean(outputstruct(ii).consumeout(:,1), p.smoothwin));
end
hold off
xlabel('Trials')
ylabel('Licks/s')
title('Consumption window')
legend(p.labels)

% 4. Trig lick bar
subplot(1,6,4)
hold on
for ii = 1 : nset
    plot(ones(outputstruct(ii).n,1) * ii, outputstruct(ii).consumemeans, '.');
    line([ii-0.3 ii+0.3], mean(outputstruct(ii).consumemeans) * [1 1], 'LineWidth', 3);
end
hold off
set(gca, 'XTick', 1 : nset);
set(gca, 'XTickLabel', p.labels);
ylabel('Licks/s')
title('Consumption window')

% 5. Trig lick vector
subplot(1,6,5)
hold on
for ii = 1 : nset
    plot(movmean(outputstruct(ii).succout(:,1), p.smoothwin));
end
hold off
xlabel('Trials')
ylabel('Success chance')
title('Success rate')
legend(p.labels)

% 6. Trig lick bar
subplot(1,6,6)
hold on
for ii = 1 : nset
    plot(ones(outputstruct(ii).n,1) * ii, outputstruct(ii).succmeans, '.');
    line([ii-0.3 ii+0.3], mean(outputstruct(ii).succmeans) * [1 1], 'LineWidth', 3);
end
hold off
set(gca, 'XTick', 1 : nset);
set(gca, 'XTickLabel', p.labels);
ylabel('Success chance')
title('Success rate')
end