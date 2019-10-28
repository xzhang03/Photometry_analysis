function [datastruct, n_series] = mkdatastruct(inputloadingcell, varargin)
% mkdatastruct makes a data structure based on the input data addresses.
% [datastruct, n_series] = mkdatastruct(inputloadingcell, defaultpath)

% Parse input
p = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Defaul where to find data
addOptional(p, 'loadisosbestic', false); % Load the 405 channel data instead of the signal

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Initialize
% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath);

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
    if ~p.loadisosbestic
        % Load photometry things
        loaded = load (fullfile(loadingcell{i,1}, loadingcell{i,2}), 'signal', 'freq');
        datastruct(i).photometry = loaded.signal;
        datastruct(i).Fs = loaded.freq;
    else
        % Load photometry things
        loaded = load (fullfile(loadingcell{i,1}, loadingcell{i,2}), 'ch2_to_fix', 'freq');
        datastruct(i).photometry = loaded.ch2_to_fix;
        datastruct(i).Fs = loaded.freq;
    end
    
    % Load behavior things
    loaded = load (fullfile(loadingcell{i,1}, loadingcell{i,3}), 'B');
    datastruct(i).behavior = unique(loaded.B,'rows'); % Remove duplicate rows
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
end