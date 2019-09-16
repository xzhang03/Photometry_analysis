function Flags = tcpCheck(inputloadingcell, defaultpath)
% tcpCheck checks the data processing status
% Flags = tcpCheck(inputloadingcell, defaultpath)

if nargin < 2
    % Default path
    defaultpath = '\\anastasia\data\photometry';
end

% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, defaultpath);

% Grabbing basic data
n_expts = size(inputloadingcell, 1);

% Flag (0 - good, 1 - no experiment, 2 - no preprocess, 3 - no align)
Flags = nan(n_expts, 1);

% Start
fprintf('========== Checking %i experiments ==========\n', n_expts);

% Loop through
for i = 1 : n_expts
    if ~exist(fullfile(loadingcell{i, 1}, loadingcell{i, 3}), 'file')
        % No experiment
        Flags(i) = 1;
        
    elseif ~exist(fullfile(loadingcell{i, 1}, loadingcell{i, 4}), 'file')
        % No preprocess
        Flags(i) = 2;
        
    elseif ~exist(fullfile(loadingcell{i, 1}, loadingcell{i, 2}), 'file')
        % No align
        Flags(i) = 3;
        
    end
    
    % Grab name
    experiment_name = loadingcell{i,2};
    
    if length(inputloadingcell{i,1}) == 5
        experiment_name = experiment_name(1:16);
    elseif length(inputloadingcell{i,1}) == 4
        experiment_name = experiment_name(1:15);
    end
    
    % Report
    switch Flags(i)
        case 1
            fprintf('%s: missing data\n', experiment_name);
        case 2
            fprintf('%s: missing preprocessing\n', experiment_name);
        case 3
            fprintf('%s: missing alignment\n', experiment_name);            
    end
end
end