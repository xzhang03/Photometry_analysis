function outputstruct = viewlickstructRNG(datacell, varargin)
% View lick data. This is the version to compare stim/no stim
%% Parse inputs
if nargin < 2
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'labels', {});
addOptional(p, 'boollabels', {'Stim', 'Nostim'})
addOptional(p, 'trimwin', []); % Trials beyond here are removed, less than this are getting patted with nans

% Plot
addOptional(p, 'pos', [150 550 800 300]);

% Subselection (based on history)
addOptional(p, 'subselpass', []); % make sure the trial numbers match
addOptional(p, 'subselfail', []);

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
trigcellpass = cell(nset, 1);
trigcellfail = cell(nset, 1);
consumecellpass = cell(nset, 1);
consumecellfail = cell(nset, 1);
succcellpass = cell(nset, 1);
succcellfail = cell(nset, 1);
passcell = cell(nset, 1);
lcell = cell(nset,1);

for ii = 1 : nset
    % Initialize matrix
    l = length(datacell{ii});
    trigmatpass = nan(p.trimwin, l);
    trigmatfail = nan(p.trimwin, l);
    consumematpass = nan(p.trimwin, l);
    consumematfail = nan(p.trimwin, l);
    succmatpass = nan(p.trimwin, l);
    succmatfail = nan(p.trimwin, l);
    passmat = nan(p.trimwin, l);
    failmat = nan(p.trimwin, l);
    
    for i = 1 : l
        % Get n
        n = datacell{ii}(i).ntrials;
        n = min(n, p.trimwin);
        
        % pass
        passvec = datacell{ii}(i).RNGvec > 0;
        failvec = ~passvec;
        
        % Parse subselection
        if ~isempty(p.subselpass)
            subpassthresh = sum(~isnan(p.subselpass)); % Has to match this number of trials
            subfailthresh = sum(~isnan(p.subselfail)); % Has to match this number of trials
            
            for isub = 1 : n
                if passvec(isub)
                    if sum(datacell{ii}(i).RNGhist(isub,:) == p.subselpass) < subpassthresh
                        passvec(isub) = false;
                    end
                end
                if failvec(isub)
                    if sum(datacell{ii}(i).RNGhist(isub,:) == p.subselfail) < subfailthresh
                        failvec(isub) = false;
                    end
                end
            end
        end
        
        % Load
        trigmatpass(1:n, i) = datacell{ii}(i).triglick(1:n);
        trigmatpass(~passvec,i) = nan;
        trigmatfail(1:n, i) = datacell{ii}(i).triglick(1:n);
        trigmatfail(~failvec,i) = nan;
        consumematpass(1:n, i) = datacell{ii}(i).consumelick(1:n);
        consumematpass(~passvec,i) = nan;
        consumematfail(1:n, i) = datacell{ii}(i).consumelick(1:n);
        consumematfail(~failvec,i) = nan;
        succmatpass(1:n, i) = datacell{ii}(i).success(1:n);
        succmatpass(~passvec,i) = nan;
        succmatfail(1:n, i) = datacell{ii}(i).success(1:n);
        succmatfail(~failvec,i) = nan;
        passmat(1:n, i) = passvec(1:n);
        failmat(1:n, i) = failvec(1:n);
    end
    
    trigcellpass{ii} = trigmatpass;
    trigcellfail{ii} = trigmatfail;
    consumecellpass{ii} = consumematpass;
    consumecellfail{ii} = consumematfail;
    succcellpass{ii} = succmatpass;
    succcellfail{ii} = succmatfail;
    passcell{ii} = passmat;
    lcell{ii} = l;
end

%% Make output
% Initialize
outputstruct = struct('label', '', 'trigmeanspass', [], 'trigmeansfail', [],...
    'consumemeanspass', [], 'consumemeansfail', [], 'succmeanspass', [], 'succmeansfail', [],...
    'pass', [], 'npass', [], 'nfail', [], 'l', []);
outputstruct = repmat(outputstruct, [nset 1]);

for ii = 1 : nset
    % Load results into output
    outputstruct(ii).label = p.labels{ii};
    
    % Trig
    outputstruct(ii).trigmeanspass = nanmean(trigcellpass{ii}, 1)';
    outputstruct(ii).trigmeansfail = nanmean(trigcellfail{ii}, 1)';
    
    % Consume
    outputstruct(ii).consumemeanspass = nanmean(consumecellpass{ii}, 1)';
    outputstruct(ii).consumemeansfail = nanmean(consumecellfail{ii}, 1)';
    
    % Success
    outputstruct(ii).succmeanspass = nanmean(succcellpass{ii}, 1)';
    outputstruct(ii).succmeansfail = nanmean(succcellfail{ii}, 1)';
    
    % pass
    outputstruct(ii).pass = passcell{ii};
    outputstruct(ii).npass = nansum(outputstruct(ii).pass);
    outputstruct(ii).nfail = nansum(~outputstruct(ii).pass);
    
    % l
    outputstruct(ii).l = lcell{ii};
end

%% Make plot
for i = 1 : nset
    figure('position', p.pos, 'Name', p.labels{i});
    
    % 1. Trig lick bar
    subplot(1,3,1)
    hold on
    for ii = 1 : 2
        switch ii
            case 1
                field = 'trigmeanspass';
            case 2
                field = 'trigmeansfail';
        end
        plot(ones(outputstruct(i).l,1) * ii, outputstruct(i).(field), '.');
        line([ii-0.3 ii+0.3], nanmean(outputstruct(i).(field)) * [1 1], 'LineWidth', 3);
    end
    hold off
    set(gca, 'XTick', 1 : 2);
    set(gca, 'XTickLabel', p.boollabels);
    ylabel('Licks/s')
    title('Trigger window')
    
    % 2. Consume lick bar
    subplot(1,3,2)
    hold on
    for ii = 1 : 2
        switch ii
            case 1
                field = 'consumemeanspass';
            case 2
                field = 'consumemeansfail';
        end
        plot(ones(outputstruct(i).l,1) * ii, outputstruct(i).(field), '.');
        line([ii-0.3 ii+0.3], mean(outputstruct(i).(field)) * [1 1], 'LineWidth', 3);
    end
    hold off
    set(gca, 'XTick', 1 : 2);
    set(gca, 'XTickLabel', p.boollabels);
    ylabel('Licks/s')
    title('Consumption window')
    
    % 6. Trig lick bar
    subplot(1,3,3)
    hold on
    for ii = 1 : 2
        switch ii
            case 1
                field = 'succmeanspass';
            case 2
                field = 'succmeansfail';
        end
        plot(ones(outputstruct(i).l,1) * ii, outputstruct(i).(field), '.');
        line([ii-0.3 ii+0.3], mean(outputstruct(i).(field)) * [1 1], 'LineWidth', 3);
    end
    hold off
    set(gca, 'XTick', 1 : 2);
    set(gca, 'XTickLabel', p.boollabels);
    ylabel('Success chance')
    title('Success rate')
end

end