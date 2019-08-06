%% Initialize
clear

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
    'Escape', 0, 'Dig', 0, 'Feed', 0, 'LBgroom', 0, 'UBgroom', 0,...
    'nFemInvest', 0, 'nCloseExam', 0, 'nMount', 0, 'nIntrom', 0,...
    'nTransfer', 0, 'nEscape', 0, 'nDig', 0, 'nFeed', 0, 'nLBgroom', 0,...
    'nUBgroom', 0);
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

%% Parse behavior codes
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
                datastruct(i).nFemInvest = datastruct(i).nFemInvest + 1;
            case 0.5
                % Close examination
                datastruct(i).CloseExam(startind:stopind) = 1;
                datastruct(i).nCloseExam = datastruct(i).nCloseExam + 1;
            case 1
                % Mounting
                datastruct(i).Mount(startind:stopind) = 1;
                datastruct(i).nMount = datastruct(i).nMount + 1;
            case 2
                % Gaining intromission
                datastruct(i).Introm(startind:stopind) = 1;
                datastruct(i).nIntrom = datastruct(i).nIntrom + 1;
            case 3
                % Transfer fluids
                datastruct(i).Transfer(startind:stopind) = 1;
                datastruct(i).nTransfer = datastruct(i).nTransfer + 1;
            case 4
                % Attemp to escape
                datastruct(i).Escape(startind:stopind) = 1;
                datastruct(i).nEscape = datastruct(i).nEscape + 1;
            case 5
                % Digging
                datastruct(i).Dig(startind:stopind) = 1;
                datastruct(i).nDig = datastruct(i).nDig + 1;
            case 6
                % Feeding
                datastruct(i).Feed(startind:stopind) = 1;
                datastruct(i).nFeed = datastruct(i).nFeed + 1;
            case 7
                % Lower-body grooming
                datastruct(i).LBgroom(startind:stopind) = 1;
                datastruct(i).nLBgroom = datastruct(i).nLBgroom + 1;
            case 8
                % Upper-body grooming
                datastruct(i).UBgroom(startind:stopind) = 1;
                datastruct(i).nUBgroom = datastruct(i).nUBgroom + 1;
                
        end
    end
end

%% Postprocess photometry data
% Initialize
datastruct_pp = struct('photometry', 0, 'Fs', 0,...
    'FemInvest', 0, 'CloseExam', 0, 'Mount', 0, 'Introm', 0, 'Transfer', 0,...
    'Escape', 0, 'Dig', 0, 'Feed', 0, 'LBgroom', 0, 'UBgroom', 0);
datastruct_pp = repmat(datastruct_pp, [size(loadingcell,1), 1]);

% Downsampled sampling rate
Fs_ds = 5;

% Smoothing window
smooth_window = 5;

% Bad frames for zscore (filter artifacts)
zscore_badframes = 1 : 10;

% loop through and parse
for i = 1 : n_series
    % Photometry
    % Binning
    datastruct_pp(i).photometry =...
        tcpBin(datastruct(i).photometry, datastruct(i).Fs, Fs_ds, 'mean', 1, true);
    % Smoothing
    datastruct_pp(i).photometry =...
        smooth(datastruct_pp(i).photometry, smooth_window);
    % Zscoring
    datastruct_pp(i).photometry =...
        tcpZscore(datastruct_pp(i).photometry, zscore_badframes);
    
    % New frame rate
    datastruct_pp(i).Fs = Fs_ds;
    
    % Female investigation
    datastruct_pp(i).FemInvest =...
        tcpBin(datastruct(i).FemInvest, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nFemInvest = datastruct(i).nFemInvest;
    
    % Close examination
    datastruct_pp(i).CloseExam =...
        tcpBin(datastruct(i).CloseExam, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nCloseExam = datastruct(i).nCloseExam;
    
    % Mount
    datastruct_pp(i).Mount =...
        tcpBin(datastruct(i).Mount, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nMount = datastruct(i).nMount;
    
    % Intromission
    datastruct_pp(i).Introm =...
        tcpBin(datastruct(i).Introm, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nIntrom = datastruct(i).nIntrom;
    
    % Transfer
    datastruct_pp(i).Transfer =...
        tcpBin(datastruct(i).Transfer, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nTransfer = datastruct(i).nTransfer;
    
    % Escape
    datastruct_pp(i).Escape =...
        tcpBin(datastruct(i).Escape, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nEscape = datastruct(i).nEscape;
    
    % Dig
    datastruct_pp(i).Dig =...
        tcpBin(datastruct(i).Dig, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nDig = datastruct(i).nDig;
    
    % Feed
    datastruct_pp(i).Feed =...
        tcpBin(datastruct(i).Feed, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nFeed = datastruct(i).nFeed;
    
    % LBGroom
    datastruct_pp(i).LBgroom =...
        tcpBin(datastruct(i).LBgroom, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nLBgroom = datastruct(i).nLBgroom;
    
    % UBGroom
    datastruct_pp(i).UBgroom =...
        tcpBin(datastruct(i).LBgroom, datastruct(i).Fs, Fs_ds, 'max', 1, true);
    datastruct_pp(i).nUBgroom = datastruct(i).nUBgroom;
end

%% Make an intromission construct
% Normalized length (in points)
norm_length = 40;

% Initialize
Intromstruct = struct('session', 0, 'data', 0, 'ln_data', 0,...
    'length', 0, 'order', 0, 'rorder', 0, 'Fs', 0);
Intromstruct = repmat(Intromstruct, [sum([datastruct_pp(:).nIntrom]), 1]);

% loop through and parse
ind = 0;
for i = 1 : n_series
    % Get behavior table
    bhv_tab_temp = chainfinder(datastruct_pp(i).Introm > 0.5);
    
    % Loop through each intromission
    for j = 1 : size(bhv_tab_temp, 1)
        % index
        ind = ind + 1;
        
        % Fill name
        Intromstruct(ind).session = i;
        
        % Fill Fs
        Intromstruct(ind).Fs = datastruct_pp(i).Fs;
        
        % Fill length
        Intromstruct(ind).length = bhv_tab_temp(j, 2);
        
        % Fill order
        Intromstruct(ind).order = j;
        
        % Fill reverse order
        Intromstruct(ind).rorder = datastruct_pp(i).nIntrom - j;
        
        % Fill data
        Intromstruct(ind).data = ...
            datastruct_pp(i).photometry(bhv_tab_temp(j, 1)...
            : (bhv_tab_temp(j, 1) + bhv_tab_temp(j, 2) - 1));
        
        % Fill length-normalized data
        % resampling factor
        rsfactor = norm_length / Intromstruct(ind).length;
        if rsfactor == 1
            Intromstruct(ind).ln_data = Intromstruct(ind).data;
        else
            Intromstruct(ind).ln_data = ...
                tcpBin(Intromstruct(ind).data, Intromstruct(ind).Fs,...
                Intromstruct(ind).Fs * rsfactor, 'mean', 1, true);
        end
    end
end
