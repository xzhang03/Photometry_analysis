function [DLCstruct, n_series] = mkDLCstruct(inputloadingcell, varargin)
% mkdatastruct makes a data structure based on the input DLC data.
% [datastruct, n_series] = mkDLCstruct(inputloadingcell, varargin)

% Parse input
p = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Defaul where to find data

% Loading parameters
addOptional(p, 'sourcetype', 'table'); % Source type: table or mat
addOptional(p, 'poscolumn', 1); % Positional column
addOptional(p, 'distcolumn', 3); % Which column to read for disntace
addOptional(p, 'confcolumn', 4); % Which column is the DLC confidence column
addOptional(p, 'fps', 30); % I think this is manual for now

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
DLCstruct = struct('dist', 0, 'pos', 0, 'speed', 0, 'conf', 0, 'fps', p.fps, 'behavior', 0,...
    'FemInvest', 0, 'CloseExam', 0, 'Mount', 0, 'Introm', 0, 'Transfer', 0,...
    'Escape', 0, 'Dig', 0, 'Feed', 0, 'LBgroom', 0, 'UBgroom', 0,...
    'nFemInvest', 0, 'nCloseExam', 0, 'nMount', 0, 'nIntrom', 0,...
    'nTransfer', 0, 'nEscape', 0, 'nDig', 0, 'nFeed', 0, 'nLBgroom', 0,...
    'nUBgroom', 0);
DLCstruct = repmat(DLCstruct, [size(loadingcell,1), 1]);

% Load data
for i = 1 : n_series
    % Load DLC things
    DLC = load (fullfile(loadingcell{i,1}, loadingcell{i,8}));
    
    % Convert table
    switch p.sourcetype
        case 'table'
            DLC = DLC.outT;
            DLC = table2array(DLC);
    end
    
    % Save
    DLCstruct(i).dist = DLC(:,p.distcolumn);
    DLCstruct(i).pos = DLC(:,p.poscolumn);
    DLCstruct(i).conf = DLC(:,p.confcolumn);
    
    % Load behavior things
    B = load (fullfile(loadingcell{i,1}, loadingcell{i,3}), 'B');
    DLCstruct(i).behavior = unique(B.B,'rows'); % Remove duplicate rows
end

%% Parse behavior codes
% loop through and parse
for i = 1 : n_series
    % Initialize all vectors
    npts = length(DLCstruct(i).dist);
    DLCstruct(i).FemInvest     = zeros(npts, 1);
    DLCstruct(i).CloseExam     = zeros(npts, 1);
    DLCstruct(i).Mount         = zeros(npts, 1);
    DLCstruct(i).Introm        = zeros(npts, 1);
    DLCstruct(i).Transfer      = zeros(npts, 1);
    DLCstruct(i).Escape        = zeros(npts, 1);
    DLCstruct(i).Dig           = zeros(npts, 1);
    DLCstruct(i).Feed          = zeros(npts, 1);
    DLCstruct(i).LBgroom       = zeros(npts, 1);
    DLCstruct(i).UBgroom       = zeros(npts, 1);
    
    % Loop through the main behavior matrix
    for j = 1 : size(DLCstruct(i).behavior, 1)
        % figure out the start and end indices
        startind = ...
            round(DLCstruct(i).behavior(j,2) * DLCstruct(i).fps * 60);
        stopind = ...
            round(DLCstruct(i).behavior(j,3) * DLCstruct(i).fps * 60);
        
        switch DLCstruct(i).behavior(j,1)
            
            case 0
                % Investigation period
                DLCstruct(i).FemInvest(startind:stopind) = 1;
                DLCstruct(i).nFemInvest = DLCstruct(i).nFemInvest + 1;
            case 0.5
                % Close examination
                DLCstruct(i).CloseExam(startind:stopind) = 1;
                DLCstruct(i).nCloseExam = DLCstruct(i).nCloseExam + 1;
            case 1
                % Mounting
                DLCstruct(i).Mount(startind:stopind) = 1;
                DLCstruct(i).nMount = DLCstruct(i).nMount + 1;
            case 2
                % Gaining intromission
                DLCstruct(i).Introm(startind:stopind) = 1;
                DLCstruct(i).nIntrom = DLCstruct(i).nIntrom + 1;
            case 3
                % Transfer fluids
                DLCstruct(i).Transfer(startind:stopind) = 1;
                DLCstruct(i).nTransfer = DLCstruct(i).nTransfer + 1;
            case 4
                % Attemp to escape
                DLCstruct(i).Escape(startind:stopind) = 1;
                DLCstruct(i).nEscape = DLCstruct(i).nEscape + 1;
            case 5
                % Digging
                DLCstruct(i).Dig(startind:stopind) = 1;
                DLCstruct(i).nDig = DLCstruct(i).nDig + 1;
            case 6
                % Feeding
                DLCstruct(i).Feed(startind:stopind) = 1;
                DLCstruct(i).nFeed = DLCstruct(i).nFeed + 1;
            case 7
                % Lower-body grooming
                DLCstruct(i).LBgroom(startind:stopind) = 1;
                DLCstruct(i).nLBgroom = DLCstruct(i).nLBgroom + 1;
            case 8
                % Upper-body grooming
                DLCstruct(i).UBgroom(startind:stopind) = 1;
                DLCstruct(i).nUBgroom = DLCstruct(i).nUBgroom + 1;
                
        end
    end
end
end