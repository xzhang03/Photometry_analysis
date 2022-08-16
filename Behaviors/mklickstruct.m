function lickstruct = mklickstruct(inputloadingcell, varargin)
%% Consolidate licking data
%% Parse inputs
if nargin < 2
    varargin = {};
end

p = inputParser;

% General parameters
addOptional(p, 'defaultpath', '\\anastasia\data\photometry');

% Windows
addOptional(p, 'trialtrigger', 'buzz'); % buzz or ensure
addOptional(p, 'trigwindow', 1); % Duration of trigger window in sec
addOptional(p, 'consumewindow', 5); % Duration of consumption window in sec

% Same-color Opto RNG analysis
addOptional(p, 'SCoptoRNG', false);
addOptional(p, 'RNGhistorywin', [-5 0]); % Default [-5 0] means 5 previous till current
addOptional(p, 'RNGhistoryX', 10); % Shows the number of stims in the last X trials (regardless of order)

% Consolidate by mice
addOptional(p, 'consolidate', true);
addOptional(p, 'consolidatebystacking', false); %% Stacking days instead of means, good for RNG analysis 

% debug
addOptional(p, 'lickstruct', []); % Directly pass lickstruct to test consolidation


% Unpack if needed
if iscell(varargin) && size(varargin,1) * size(varargin,2) == 1
    varargin = varargin{:};
end

parse(p, varargin{:});
p = p.Results;

%% Load
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath);
n_loadingcell = size(loadingcell, 1);
if isempty(p.lickstruct)
    % Initialize
    lickstruct = struct('mouse', [], 'ntrials', [], 'triglick', [], 'triglickmean', [],...
        'consumelick', [], 'consumelickmean', [], 'success', [], 'successmean', []);
    lickstruct = repmat(lickstruct, [n_loadingcell, 1]);
    
    % Load
    hwait = waitbar(0, 'Processing');
    for i = 1 : n_loadingcell
%         disp(i);
        waitbar(i/n_loadingcell, hwait, sprintf('Processing %i/%i', i, n_loadingcell))
        fpath = fullfile(loadingcell{i,1}, loadingcell{i,5});
        out = lickanalysis('fpath', fpath, 'makeplot', false, 'trigwindow', ...
            p.trigwindow, 'consumewindow', p.consumewindow, 'SCoptoRNG', p.SCoptoRNG,...
            'RNGhistorywin', p.RNGhistorywin, 'RNGhistoryX', p.RNGhistoryX, 'trialtrigger',...
            p.trialtrigger);
        lickstruct(i).mouse = inputloadingcell{i,1};
        lickstruct(i).ntrials = length(out.triglick);
        lickstruct(i).triglick = out.triglick;
        lickstruct(i).triglickmean = mean(out.triglick);
        lickstruct(i).consumelick = out.consumelick;
        lickstruct(i).consumelickmean = mean(out.consumelick);
        lickstruct(i).success = out.success;
        lickstruct(i).successmean = mean(out.success);
        lickstruct(i).RNGvec = out.RNGvec;
        lickstruct(i).RNGhist = out.RNGhist;
        lickstruct(i).RNGX = out.RNGX;
    end
    close(hwait)
else
    lickstruct = p.lickstruct;
end
%% Consolidate
if p.consolidate
    % Get unique mice
    mice = inputloadingcell(:,1);
    uniquemice = unique(mice);
    nmice = length(uniquemice);
    
    % Initialize
    lickstructcons = struct('mouse', [], 'totaltrials', [], 'ntrials', [], 'triglick', [], 'triglickmean', [],...
        'consumelick', [], 'consumelickmean', [], 'success', [], 'successmean', []);
    lickstructcons = repmat(lickstructcons, [nmice, 1]);
    
    % Consolidate
    hwait = waitbar(0, 'Consolidating');
    for i = 1 : nmice
        waitbar(i/nmice, hwait, sprintf('Consolidating %i/%i', i, nmice))
        
        % Get mouse
        mouse = uniquemice{i};
        inds = strcmp(mice, mouse);
        
        % Mouse
        lickstructcons(i).mouse = mouse;
        
        % Trials
        ntrials = [lickstruct(inds).ntrials];
        if std(ntrials) > 0
            % Going to need to pad some sessions with nans
            ntrials(:) = max(ntrials);
            nanpadding = true;
        else
            nanpadding = false;
        end
        lickstructcons(i).totaltrials = sum(ntrials);
        if p.consolidatebystacking
            lickstructcons(i).ntrials = sum(ntrials);
        else
            lickstructcons(i).ntrials = max(ntrials);
        end
        
        % Triglick
        triglick = {lickstruct(inds).triglick};
        if nanpadding
            triglick = nanpad(triglick, max(ntrials), false);
        end
        if p.consolidatebystacking
            lickstructcons(i).triglick = reshape(cell2mat(triglick), [sum(ntrials), 1]);
        else
            lickstructcons(i).triglick = nanmean(cell2mat(triglick), 2);
        end
        lickstructcons(i).triglickmean = mean([lickstruct(inds).triglickmean]);
        
        % Consume
        consumelick = {lickstruct(inds).consumelick};
        if nanpadding
            consumelick = nanpad(consumelick, max(ntrials), false);
        end
        if p.consolidatebystacking
            lickstructcons(i).consumelick = reshape(cell2mat(consumelick), [sum(ntrials), 1]);
        else
            lickstructcons(i).consumelick = nanmean(cell2mat(consumelick), 2);
        end
        lickstructcons(i).consumelickmean = mean([lickstruct(inds).consumelickmean]);
        
        % Success
        success = {lickstruct(inds).success};
        if nanpadding
            success = nanpad(success, max(ntrials), false);
        end
        if p.consolidatebystacking
            lickstructcons(i).success = reshape(cell2mat(success), [sum(ntrials), 1]);
        else
            lickstructcons(i).success = nanmean(cell2mat(success), 2);
        end
        lickstructcons(i).successmean = mean([lickstruct(inds).successmean]);
        
        % RNG
        RNGvec = {lickstruct(inds).RNGvec};
        RNGhist = {lickstruct(inds).RNGhist};
        RNGX = {lickstruct(inds).RNGX};
        if nanpadding
            RNGvec = nanpad(RNGvec, max(ntrials), false, 1);
            RNGhist = nanpad(RNGhist, max(ntrials), false, 1);
            RNGX = nanpad(RNGX, max(ntrials), false, 1);
        end
        histl = size(RNGhist{1}, 2);
        Xl = size(RNGX{1}, 2);
        if p.consolidatebystacking
            lickstructcons(i).RNGvec = reshape(cell2mat(RNGvec), [sum(ntrials), 1]);
        else
            lickstructcons(i).RNGvec = RNGvec;
        end
        if p.consolidatebystacking
            RNGhist = cellfun(@transpose, RNGhist, 'UniformOutput', false);
            lickstructcons(i).RNGhist = reshape(cell2mat(RNGhist), [histl, sum(ntrials)]);
            lickstructcons(i).RNGhist = lickstructcons(i).RNGhist';
        else
            lickstructcons(i).RNGhist = RNGhist;
        end
        if p.consolidatebystacking
            RNGX = cellfun(@transpose, RNGX, 'UniformOutput', false);
            lickstructcons(i).RNGX = reshape(cell2mat(RNGX), [Xl, sum(ntrials)]);
            lickstructcons(i).RNGX = lickstructcons(i).RNGX';
        else
            lickstructcons(i).RNGX = RNGX;
        end
    end
    lickstruct = lickstructcons;
    close(hwait)
end

end
