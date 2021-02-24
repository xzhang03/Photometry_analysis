function DLCstruct_pp = ppDLCstruct(DLCstruct, varargin)
% ppDLCstruct post-process DLC structure and trigger
% DLCstruct_pp = ppDLCstruct(DLCstruct, varargin)

% Parse inputs
p = inputParser;

addOptional(p, 'Fs_ds', 1); % Fps to downsample to
addOptional(p, 'dsmethod', 'nanmedian'); % Down sample method
addOptional(p, 'smooth_window', 5); % Window size for smoothing
addOptional(p, 'conf_thresh', 0.5); % Confidence threshold

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Clean up inputs and initialize
% N
n = size(DLCstruct,1);

% Initialize
DLCstruct_pp = DLCstruct;

%% Loop through and post process
for i = 1 : n
    % Apply confidence threshold
    dist = DLCstruct(i).dist;
    dist(DLCstruct(i).conf < p.conf_thresh) = nan;
    pos = DLCstruct(i).pos;
    pos(DLCstruct(i).conf < p.conf_thresh) = nan;
    conf = DLCstruct(i).conf;
    conf(DLCstruct(i).conf < p.conf_thresh) = nan;
        
    % Bin
    dist = tcpBin(dist, DLCstruct(i).fps, p.Fs_ds, p.dsmethod, 1, true);
    pos = tcpBin(pos, DLCstruct(i).fps, p.Fs_ds, p.dsmethod, 1, true);
    conf = tcpBin(conf, DLCstruct(i).fps, p.Fs_ds, p.dsmethod, 1, true);
    
    % Smooth if asked
    if p.smooth_window > 1
        dist = smooth(dist, p.smooth_window);
        pos = smooth(pos, p.smooth_window);
        conf = smooth(conf, p.smooth_window);
    end
    
    % Get speed
    speed = abs(diff(pos));
    speed(end+1) = nan;
    
    % Save
    DLCstruct_pp(i).dist = dist;
    DLCstruct_pp(i).pos = pos;
    DLCstruct_pp(i).conf = conf;
    DLCstruct_pp(i).speed = speed;
    DLCstruct_pp(i).fps = p.Fs_ds;
    
    % Behavioral codes
    % Female investigation
    if isfield(DLCstruct, 'FemInvest')
        DLCstruct_pp(i).FemInvest =...
            tcpBin(DLCstruct(i).FemInvest, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nFemInvest = DLCstruct(i).nFemInvest;
    end
    
    % Close examination
    if isfield(DLCstruct, 'CloseExam')
        DLCstruct_pp(i).CloseExam =...
            tcpBin(DLCstruct(i).CloseExam, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nCloseExam = DLCstruct(i).nCloseExam;
    end
    
    % Mount
    if isfield(DLCstruct, 'Mount')
        DLCstruct_pp(i).Mount =...
            tcpBin(DLCstruct(i).Mount, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nMount = DLCstruct(i).nMount;
    end
    
    % Intromission
    if isfield(DLCstruct, 'Introm')
        DLCstruct_pp(i).Introm =...
            tcpBin(DLCstruct(i).Introm, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nIntrom = DLCstruct(i).nIntrom;
    end
    
    % Transfer
    if isfield(DLCstruct, 'Introm')
        DLCstruct_pp(i).Transfer =...
            tcpBin(DLCstruct(i).Transfer, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nTransfer = DLCstruct(i).nTransfer;
    end
    
    % Escape
    if isfield(DLCstruct, 'Escape')
        DLCstruct_pp(i).Escape =...
            tcpBin(DLCstruct(i).Escape, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nEscape = DLCstruct(i).nEscape;
    end
    
    % Dig
    if isfield(DLCstruct, 'Dig')
        DLCstruct_pp(i).Dig =...
            tcpBin(DLCstruct(i).Dig, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nDig = DLCstruct(i).nDig;
    end
    
    % Feed
    if isfield(DLCstruct, 'Feed')
        DLCstruct_pp(i).Feed =...
            tcpBin(DLCstruct(i).Feed, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nFeed = DLCstruct(i).nFeed;
    end
    
    % LBGroom
    if isfield(DLCstruct, 'LBgroom')
        DLCstruct_pp(i).LBgroom =...
            tcpBin(DLCstruct(i).LBgroom, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nLBgroom = DLCstruct(i).nLBgroom;
    end
    
    % UBGroom
    if isfield(DLCstruct, 'UBgroom')
        DLCstruct_pp(i).UBgroom =...
            tcpBin(DLCstruct(i).LBgroom, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nUBgroom = DLCstruct(i).nUBgroom;
    end
    
    % UBGroom
    if isfield(DLCstruct, 'Approach')
        DLCstruct_pp(i).Approach =...
            tcpBin(DLCstruct(i).Approach, DLCstruct(i).fps, p.Fs_ds, 'max', 1, true);
        DLCstruct_pp(i).nApproach = DLCstruct(i).nApproach;
    end
end

end