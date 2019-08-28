function datastruct_pp = ppdatastruct(datastruct, varargin)
% ppdatastruct post-process data structure
% datastruct_pp = ppdatastruct(datastruct, ppcfg)

% Parse inputs
p = inputParser;

addOptional(p, 'Fs_ds', 5); % Fps to downsample to
addOptional(p, 'smooth_window', 5); % Window size for smoothing
addOptional(p, 'zscore_badframes', 1:10);   % Frames to throw away when 
                                            % calculating z-scores
addOptional(p, 'BlankTime', 20);    % Numerb of seconds to keep  after the 
                                    % last behavioral score. Leave empty if
                                    % no chopping.
addOptional(p, 'First_point', 1); % Throw away the first X points.                                            


% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Initialize
datastruct_pp = struct('photometry', 0, 'Fs', 0,...
    'FemInvest', 0, 'CloseExam', 0, 'Mount', 0, 'Introm', 0, 'Transfer', 0,...
    'Escape', 0, 'Dig', 0, 'Feed', 0, 'LBgroom', 0, 'UBgroom', 0);
datastruct_pp = repmat(datastruct_pp, [size(datastruct,1), 1]);

% Downsampled sampling rate
Fs_ds = p.Fs_ds;

% Smoothing window
smooth_window = p.smooth_window;

% Bad frames for zscore (filter artifacts)
zscore_badframes = p.zscore_badframes;

% loop through and parse
for i = 1 : size(datastruct,1)
        
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
    
    % Chopping if needed
    if ~isempty(p.BlankTime)
        
        % Last time point
        last_active_time = max(datastruct(i).behavior(:,3)) * 60;
        last_kept_point = round((last_active_time + p.BlankTime) * Fs_ds);
        
        % Keep the last point in range
        last_kept_point = min(last_kept_point, length(datastruct_pp(i).photometry));

        % Chopping
        datastruct_pp(i).photometry = datastruct_pp(i).photometry(p.First_point : last_kept_point);
        datastruct_pp(i).FemInvest = datastruct_pp(i).FemInvest(p.First_point : last_kept_point);
        datastruct_pp(i).CloseExam = datastruct_pp(i).CloseExam(p.First_point : last_kept_point);
        datastruct_pp(i).Mount = datastruct_pp(i).Mount(p.First_point : last_kept_point);
        datastruct_pp(i).Introm = datastruct_pp(i).Introm(p.First_point : last_kept_point);
        datastruct_pp(i).Transfer = datastruct_pp(i).Transfer(p.First_point : last_kept_point);
        datastruct_pp(i).Escape = datastruct_pp(i).Escape(p.First_point : last_kept_point);
        datastruct_pp(i).Dig = datastruct_pp(i).Dig(p.First_point : last_kept_point);
        datastruct_pp(i).Feed = datastruct_pp(i).Feed(p.First_point : last_kept_point);
        datastruct_pp(i).LBgroom = datastruct_pp(i).LBgroom(p.First_point : last_kept_point);
        datastruct_pp(i).UBgroom = datastruct_pp(i).UBgroom(p.First_point : last_kept_point);

    end
    
end
end