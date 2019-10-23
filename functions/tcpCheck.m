function Flags = tcpCheck(inputloadingcell, varargin)
% tcpCheck checks the data processing status
% Flags = tcpCheck(inputloadingcell, varargin)

% Parser inputs
p = inputParser;
addOptional(p, 'defaultpath', '\\anastasia\data\photometry');
addOptional(p, 'twocolor', true);
addOptional(p, 'headfixed', false);

if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;


% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath);

% Grabbing basic data
n_expts = size(inputloadingcell, 1);

% Flag (0 - good, 1 - no experiment, 2 - no preprocess, 3 - no align)S
% Second column for behavior file: 1 - exist
% Third column for opto (triggered): 1 - exist
Flags = nan(n_expts, 3);

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
            fprintf('%s: missing preprocessing\n', experiment_name);
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
        end
    end
    
    % Head fixed (triggering)
    if p.headfixed
        % No opto trig flie
        if Flags(i, 3) == 0
            fprintf('%s: missing triggered opto file\n', experiment_name);
        end
    end
end

fprintf('Done.\n')

end