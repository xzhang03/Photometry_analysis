function [Flags, confignames, trialstructure] = tcpCheck(inputloadingcell, varargin)
% tcpCheck checks the data processing status
% Flags = tcpCheck(inputloadingcell, varargin)

% Parser inputs
p = inputParser;
addOptional(p, 'defaultpath', 'Z:\photometry');
addOptional(p, 'twocolor', false); % Check for alignment
addOptional(p, 'headfixed', true); % Head fix mode (no A mat and with triggers)
addOptional(p, 'mousedate', true);

% Checking stuff
addOptional(p, 'checkpreprocess', true); % Check preprocessing, generally true
addOptional(p, 'checktrigger', true); % Check trigger, generally true for headfixed
addOptional(p, 'checkconfigs', false); % Check trigger, generally true for headfixed

% Trigger suffix
addOptional(p, 'trigsuffix', '');

% A mat check and fixing (old)
addOptional(p, 'checkAmat', false); % Open and check A mats (will take longer)
addOptional(p, 'checkDLC', false); % Check DLC files exist
addOptional(p, 'RangeRatioThresh', 1.3); % When the warn that the ratios are off
addOptional(p, 'AskToFixAmat', true);

if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;


% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath, p.trigsuffix, p.mousedate);

% Grabbing basic data
n_expts = size(inputloadingcell, 1);

% Flag (0 - good, 1 - no experiment, 2 - no preprocess, 3 - no align)S
% Second column for behavior file: 1 - exist
% Third column for opto (triggered): 1 - exist
% Fourth column for DLC: 1 - exist
Flags = nan(n_expts, 4);

% config names
confignames = cell(n_expts, 1);
trialstructure = struct('rig', '', 'configname', '',...
    'behavior', [], 'cueenable', [], 'cuedelay', [], 'cuedur', [], 'conditional', [], ...
    'actiondelay', [], 'actiondur', [], 'fooddelay', [], 'foodpulsewidth', [], 'foodcycle', [], 'foodtrainlength', [],...
    'ntrialtypes', [], 'trialfreq', [], 'schedulerenable', [], 'schedulerdelay', [], 'schedulertrials', []);
trialstructure = repmat(trialstructure, [n_expts 1]);

% Start
fprintf('========== Checking %i experiments ==========\n', n_expts);

% Loop through
for i = 1 : n_expts
    if ~exist(fullfile(loadingcell{i, 1}, loadingcell{i, 5}), 'file')
        % No experiment
        Flags(i, 1) = 1;
        
    elseif ~exist(fullfile(loadingcell{i, 1}, loadingcell{i, 4}), 'file')
        % No preprocess
        Flags(i, 1) = 2;
        
    elseif ~exist(fullfile(loadingcell{i, 1}, loadingcell{i, 2}), 'file')
        % No align
        Flags(i, 1) = 3;
    else
        % All set
        Flags(i, 1) = 0;
    end
    
    % Check behavioral file
    Flags(i, 2) = exist(fullfile(loadingcell{i, 1}, loadingcell{i, 3}), 'file');
    
    % Check triggered opto file
    Flags(i, 3) = exist(fullfile(loadingcell{i, 1}, loadingcell{i, 6}), 'file');
    
    % DLC
    Flags(i, 4) = exist(fullfile(loadingcell{i, 1}, loadingcell{i, 8}), 'file');
    
    % Grab name
    experiment_name = loadingcell{i,2};
    
    if length(inputloadingcell{i,1}) == 5
        experiment_name = experiment_name(1:16);
    elseif length(inputloadingcell{i,1}) == 4
        experiment_name = experiment_name(1:15);
    end
    
    % Report
    switch Flags(i, 1)
        case 1
            fprintf('%s: missing data\n', experiment_name);
        case 2
            if p.checkpreprocess
                fprintf('%s: missing preprocessing\n', experiment_name);
            end
        case 3
            if p.twocolor
                fprintf('%s: missing alignment\n', experiment_name);
            end
    end
    
    % Free-moving (scoring)
    if ~p.headfixed
        % No behavioral flie
        if Flags(i, 2) == 0
            fprintf('%s: missing behavioral file\n', experiment_name);
        elseif p.checkAmat
            % Load
            AMAT = load(fullfile(loadingcell{i, 1}, loadingcell{i, 3}));
            
            % Time range for A (using starting points)
            arange = range(AMAT.A(:,2));
            
            % Time range for B (using starting points)
            brange = range(AMAT.B(:,2));
            
            if brange/arange > p.RangeRatioThresh || arange/brange > p.RangeRatioThresh
                % Warn about range
                fprintf('%s: time ratio too large: %1.2f\n', experiment_name, brange/arange);
                
                % Try to fix A mat
                if p.AskToFixAmat
                    % Ask
                    fixornot = questdlg(sprintf('%s: time ratio too large: %1.2f. Fix?', experiment_name, brange/arange), ...
                        'Fix or not', 'Scale down 2x', 'Scale up 2x', 'No', 'Scale down 2x');
                    
                    switch fixornot
                        case 'Scale down 2x'
                            % Scale down
                            AMAT.B(:,2) = AMAT.B(:,2) / 2;
                            AMAT.B(:,3) = AMAT.B(:,3) / 2;
                            
                            % Save
                            save(fullfile(loadingcell{i, 1}, loadingcell{i, 3}), '-struct', 'AMAT');
                        case 'Scale up 2x'
                            % Scale down
                            AMAT.B(:,2) = AMAT.B(:,2) * 2;
                            AMAT.B(:,3) = AMAT.B(:,3) * 2;
                            
                            % Save
                            save(fullfile(loadingcell{i, 1}, loadingcell{i, 3}), '-struct', 'AMAT');
                    end
                end
            end
        end
    end
    
    % Head fixed (triggering)
    if p.headfixed
        % No opto trig flie
        if Flags(i, 3) == 0 && p.checktrigger
            fprintf('%s: missing triggered opto file\n', experiment_name);
        end
    end
    
    % DLC
    if p.checkDLC
        % No opto trig flie
        if Flags(i, 4) == 0
            fprintf('%s: missing DLC file\n', experiment_name);
        end
    end

    % Config
    if p.checkconfigs
        loaded = load(fullfile(loadingcell{i, 1}, loadingcell{i, 5}), 'configfp', 'omniboxsetting');
        [~, confignames{i}, ~] = fileparts(loaded.configfp);
        trialstructure(i).behavior = loaded.omniboxsetting.optodelayTTL.enable;
        trialstructure(i).ntrialtypes = loaded.omniboxsetting.optodelayTTL.ntrialtypes;
        trialstructure(i).trialfreq = loaded.omniboxsetting.optodelayTTL.trialfreq;
        trialstructure(i).cueenable = loaded.omniboxsetting.optodelayTTL.cueenable;
        trialstructure(i).cuedelay = loaded.omniboxsetting.optodelayTTL.cuedelay;
        trialstructure(i).cuedur = loaded.omniboxsetting.optodelayTTL.cuedur;
        trialstructure(i).conditional = loaded.omniboxsetting.optodelayTTL.conditional;
        trialstructure(i).actiondelay = loaded.omniboxsetting.optodelayTTL.actiondelay;
        trialstructure(i).actiondur = loaded.omniboxsetting.optodelayTTL.actiondur;
        trialstructure(i).fooddelay = loaded.omniboxsetting.optodelayTTL.delay;
        trialstructure(i).foodpulsewidth = loaded.omniboxsetting.optodelayTTL.pulsewidth;
        trialstructure(i).foodcycle = loaded.omniboxsetting.optodelayTTL.cycle;
        trialstructure(i).foodtrainlength = loaded.omniboxsetting.optodelayTTL.trainlength;
        trialstructure(i).schedulerenable = loaded.omniboxsetting.scheduler.enable;
        trialstructure(i).schedulerdelay = loaded.omniboxsetting.scheduler.delay;
        trialstructure(i).schedulertrials = loaded.omniboxsetting.scheduler.ntrains;
        trialstructure(i).rig = loaded.omniboxsetting.Rig;
        trialstructure(i).configname = confignames{i};
    end
end

if p.checkconfigs
    disp(confignames)
end

fprintf('Done.\n')

end