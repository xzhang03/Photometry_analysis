%% Initialize
% Loading cell
loadingcell = ...
    {'\\anastasia\data\photometry\SZ129\190707_SZ129', 'SZ129-190707-002-nidaq_preprocessed_fixed', 'SZ129-190707-002-A';...
    '\\anastasia\data\photometry\SZ132\190720_SZ132', 'SZ132-190720-002-nidaq_preprocessed_fixed', 'SZ132-190720-002-A';...
    '\\anastasia\data\photometry\SZ133\190709_SZ133', 'SZ133-190709-002-nidaq_preprocessed_fixed', 'SZ133-190709-002-A';...
    '\\anastasia\data\photometry\SZ133\190720_SZ133', 'SZ133-190720-002-nidaq_preprocessed_fixed', 'SZ133-190720-002-A';...
    '\\anastasia\data\photometry\SZ133\190720_SZ133', 'SZ133-190720-003-nidaq_preprocessed_fixed', 'SZ133-190720-003-A'};

% data samples
n_series = size(loadingcell, 1);

% Initialize
datastruct = struct('photometry', 0, 'behavior', 0, 'Fs', 0,...
    'FemInvest', 0, 'CloseExam', 0, 'Mount', 0, 'Introm', 0, 'Transfer', 0,...
    'Escape', 0, 'Dig', 0, 'Feed', 0, 'LBgroom', 0, 'UBgroom', 0);
datastruct = repmat(datastruct, [size(loadingcell,1), 1]);

% Load data
for i = 1 : n_series
    % Load photometry things
    loaded = load (fullfile(loadingcell{i,1}, [loadingcell{i,2}, '.mat']), 'signal', 'freq');
    datastruct(i).photometry = loaded.signal;
    datastruct(i).Fs = loaded.freq;
    
    % Load behavior things
    loaded = load (fullfile(loadingcell{i,1}, [loadingcell{i,3}, '.mat']), 'B');
    datastruct(i).behavior = loaded.B;
end

%% Parse beahvior codes
% loop through and parse
for i = 1 : n_series
    % Initialize all vectors
    npts = length(datastruct(i).photometry);
    datastruct(i).FemInvest     = zeros(npts, 1);
    datastruct(i).CloseExam     = zeros(npts, 1);
    datastruct(i).Mount         = zeros(npts, 1);
    datastruct(i).Introm        = zeros(npts, 1);
    datastruct(i).Transfer      = zeros(npts, 1);
    datastruct(i).Escape        = zeros(npts, 1);
    datastruct(i).Dig           = zeros(npts, 1);
    datastruct(i).Feed          = zeros(npts, 1);
    datastruct(i).LBgroom       = zeros(npts, 1);
    datastruct(i).UBgroom       = zeros(npts, 1);
    
    % Loop through the main behavior matrix
    for j = 1 : size(datastruct(i).behavior, 1)
        % figure out the start and end indices
        startind = ...
            round(datastruct(i).behavior(j,2) * datastruct(i).Fs * 60);
        stopind = ...
            round(datastruct(i).behavior(j,3) * datastruct(i).Fs * 60);
        
        switch datastruct(i).behavior(j,1)
            
            case 0
                % Investigation period
                datastruct(i).FemInvest(startind:stopind) = 1;
            case 0.5
                % Close examination
                datastruct(i).CloseExam(startind:stopind) = 1;
            case 1
                % Mounting
                datastruct(i).Mount(startind:stopind) = 1;
            case 2
                % Gaining intromission
                datastruct(i).Introm(startind:stopind) = 1;
            case 3
                % Transfer fluids
                datastruct(i).Transfer(startind:stopind) = 1;
            case 4
                % Attemp to escape
                datastruct(i).Escape(startind:stopind) = 1;
            case 5
                % Digging
                datastruct(i).Dig(startind:stopind) = 1;
            case 6
                % Feeding
                datastruct(i).Feed(startind:stopind) = 1;
            case 7
                % Lower-body grooming
                datastruct(i).LBgroom(startind:stopind) = 1;
            case 8
                % Upper-body grooming
                datastruct(i).UBgroom(startind:stopind) = 1;
                
        end
    end
end