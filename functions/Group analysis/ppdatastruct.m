function datastruct_pp = ppdatastruct(datastruct, varargin)
% ppdatastruct post-process data structure
% datastruct_pp = ppdatastruct(datastruct, ppcfg)

% Parse inputs
p = inputParser;

addOptional(p, 'Fs_ds', 5); % Fps to downsample to
addOptional(p, 'smooth_window', 5); % Window size for smoothing
addOptional(p, 'usedff', false); % Use a sliding window df/f
addOptional(p, 'dffwindow', 32); % Number of seconds used to calculate df/f
addOptional(p, 'dffpercentile', 10); % Default percentile for df/f
addOptional(p, 'dffOffset', 5); % Positive offset to data before df/f to 
                                % prevent sign switches
addOptional(p, 'zscore_badframes', 1:10);   % Frames to throw away when 
                                            % calculating z-scores
addOptional(p, 'BlankTime', 20);    % Numerb of seconds to keep  after the 
                                    % last behavioral score. Leave empty if
                                    % no chopping.
addOptional(p, 'First_point', 1); % Throw away the first X points.
addOptional(p, 'merging', []);  % merge datasets if needed. Input is a 
                                % vector where 0 means no merging, and 
                                % every non-zero number is merged with the
                                % dataset with the same number
addOptional(p, 'combinedzscore', false); % Combine the data together before z-scoring.

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

% Initialize a cell to contain all the photometry data to do combined
% zscore [data, number of points, bad points]
if p.combinedzscore
    combined_photom_cell = cell(size(datastruct,1), 3);
end

% loop through and parse
for i = 1 : size(datastruct,1)
        
    % Photometry
    % Binning
    datastruct_pp(i).photometry =...
        tcpBin(datastruct(i).photometry, datastruct(i).Fs, Fs_ds, 'mean', 1, true);
    
    if smooth_window > 0
        % Smoothing
        datastruct_pp(i).photometry =...
            smooth(datastruct_pp(i).photometry, smooth_window);
    end
    
    % Use df/f if needed
    if p.usedff
        datastruct_pp(i).photometry =...
            tcpPercentiledff(datastruct_pp(i).photometry + p.dffOffset, ...
            Fs_ds, p.dffwindow, p.dffpercentile);
    end
    
    % Chopping the end if needed
    if ~isempty(p.BlankTime)
        % Last time point
        last_active_time = max(datastruct(i).behavior(:,3)) * 60;
        last_kept_point = round((last_active_time + p.BlankTime) * Fs_ds);
        
        % Keep the last point in range
        last_kept_point = min(last_kept_point, length(datastruct_pp(i).photometry));
        
        datastruct_pp(i).photometry = datastruct_pp(i).photometry(p.First_point : last_kept_point);
    end
    
    % Zscoring
    datastruct_pp(i).photometry =...
        tcpZscore(datastruct_pp(i).photometry, zscore_badframes);
    
    % Store data for combined zscore if needed
    if p.combinedzscore
        % Data
        combined_photom_cell{i, 1} = datastruct_pp(i).photometry';
        
        % Number of points
        combined_photom_cell{i, 2} = length(datastruct_pp(i).photometry);
        
        % Bad points
        if i == 1
            % bad points
            combined_photom_cell{i, 3} = p.zscore_badframes;
        else
            % bad points
            combined_photom_cell{i, 3} = p.zscore_badframes...
                + sum([combined_photom_cell{1:(i-1), 2}]);
        end
    end
    
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
    
    % Chopping the end if needed
    if ~isempty(p.BlankTime)
        % Chopping
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

%% Do combined zscore if needed
if p.combinedzscore

    % Combined data
    combined_data = [combined_photom_cell{:,1}];
    
    % Combined bad points
    combined_badpoints = [combined_photom_cell{:,3}];
    
    % Combined zscored data
    combined_zscored_data = tcpZscore(combined_data, combined_badpoints);
    
    % Figure out how to distribute the data back
    nvec = [combined_photom_cell{:,2}];
    distmat = [cumsum([1,nvec(1:end-1)]) ;cumsum(nvec)]';
    
    % Distribute back
    for i = 1 : size(datastruct,1)
        % Distribute back data
        datastruct_pp(i).photometry =...
            combined_zscored_data(distmat(i,1) : distmat(i,2))';
    end
end

%% Merging datasets
if ~isempty(p.merging) && max(p.merging) > 0
    % Find unique sets to merge
    mergesets = unique(p.merging);
    
    % Find sets to remove (afterward)
    setstoremove = (diff(p.merging) == 0) .* p.merging(2:end);
    
    % never remove the first set
    setstoremove = [0, setstoremove] > 0;
    
    for i = 1 : length(mergesets)
        if mergesets(i) ~= 0
            % Which
            merge_sets_curr = p.merging == mergesets(i);

            % Where to put the merged data (first of the ones)
            settoputin = find(merge_sets_curr, 1, 'first');

            % Go through and merge data
            datastruct_pp(settoputin).photometry =...
                cell2mat({datastruct_pp(merge_sets_curr).photometry}');
            datastruct_pp(settoputin).FemInvest =...
                cell2mat({datastruct_pp(merge_sets_curr).FemInvest}');
            datastruct_pp(settoputin).CloseExam =...
                cell2mat({datastruct_pp(merge_sets_curr).CloseExam}');
            datastruct_pp(settoputin).Mount =...
                cell2mat({datastruct_pp(merge_sets_curr).Mount}');
            datastruct_pp(settoputin).Introm =...
                cell2mat({datastruct_pp(merge_sets_curr).Introm}');
            datastruct_pp(settoputin).Transfer =...
                cell2mat({datastruct_pp(merge_sets_curr).Transfer}');
            datastruct_pp(settoputin).Escape =...
                cell2mat({datastruct_pp(merge_sets_curr).Escape}');
            datastruct_pp(settoputin).Dig =...
                cell2mat({datastruct_pp(merge_sets_curr).Dig}');
            datastruct_pp(settoputin).Feed =...
                cell2mat({datastruct_pp(merge_sets_curr).Feed}');
            datastruct_pp(settoputin).LBgroom =...
                cell2mat({datastruct_pp(merge_sets_curr).LBgroom}');
            datastruct_pp(settoputin).UBgroom =...
                cell2mat({datastruct_pp(merge_sets_curr).UBgroom}');
            
            % Go through and sum counts
            datastruct_pp(settoputin).nFemInvest =...
                sum([datastruct_pp(merge_sets_curr).nFemInvest]);
            datastruct_pp(settoputin).nCloseExam =...
                sum([datastruct_pp(merge_sets_curr).nCloseExam]);
            datastruct_pp(settoputin).nMount =...
                sum([datastruct_pp(merge_sets_curr).nMount]);
            datastruct_pp(settoputin).nIntrom =...
                sum([datastruct_pp(merge_sets_curr).nIntrom]);
            datastruct_pp(settoputin).nTransfer =...
                sum([datastruct_pp(merge_sets_curr).nTransfer]);
            datastruct_pp(settoputin).nEscape =...
                sum([datastruct_pp(merge_sets_curr).nEscape]);
            datastruct_pp(settoputin).nDig =...
                sum([datastruct_pp(merge_sets_curr).nDig]);
            datastruct_pp(settoputin).nFeed =...
                sum([datastruct_pp(merge_sets_curr).nFeed]);
            datastruct_pp(settoputin).nLBgroom =...
                sum([datastruct_pp(merge_sets_curr).nLBgroom]);
            datastruct_pp(settoputin).nUBgroom =...
                sum([datastruct_pp(merge_sets_curr).nUBgroom]);
        end
    end
    
    % Reorganize the sets
    datastruct_pp = datastruct_pp(~setstoremove);
end
end