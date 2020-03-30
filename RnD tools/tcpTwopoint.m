%% Initialization
% Stephen Zhang 2019/10/20

% Use previous path if exists
if ~exist('filepath', 'var')
    clear
    % common path
    defaultpath = '\\anastasia\data\photometry';
else
    defaultpath = filepath;
    keep defaultpath
end

% Number of points to use for medians
TPCfg.npts = 100;

% Match slope
% Use exponential fit to find the slopes
TPCfg.matchslopes = true;
TPCfg.useoffset = true; % Also consider the DC offset that occurs during the skip.
TPCfg.fitfirstpt = 100; % How many points to throw out on the left for fitting
TPCfg.fitlastpt = 15; % How many points to throw out on the right for fitting
TPCfg.fitextendednpts = 10000;  % How many points to extend when applying the fit for
                                % Segment 2.



%% IO
% Work out outputpath
[filename, filepath] = uigetfile(fullfile(defaultpath , '*_preprocessed.mat'));
filename_output_twopoints = [filename(1:end-4), '_twopoints.mat'];
load(fullfile(filepath, filename), 'freq', 'ch1_data_table',...
    'Ch1_filtered', 'n_points', 'opto_pulse_table', 'Fs');

%% Parse data
% Grab time skip point
dt = diff(ch1_data_table(:,1));
[lskip, skipind] = max(dt);
fprintf('Time skip occurred at %2.1f min for %2.1f min.\n', ...
    ch1_data_table(skipind,1)/Fs/60, lskip/Fs/60);

% Get the indices
% First segment
i1 = TPCfg.fitfirstpt;
i2 = skipind - TPCfg.fitlastpt;

% Second segment
i3 = skipind + TPCfg.fitfirstpt;
i4 = n_points - TPCfg.fitlastpt;

% Fix the extended points if needed
TPCfg.fitextendednpts = max(TPCfg.fitextendednpts, i4 - i3 + 1); 

%% Grab Segments
% Grab data
Seg_1 = Ch1_filtered(i1:i2);
Seg_2 = Ch1_filtered(i3:i4);

if TPCfg.matchslopes
    % Fits
    [~, Fit_1] = tcpFlatten(Ch1_filtered(i1:i2));
    [~, Fit_2] = tcpFlatten(Ch1_filtered(i3:i4));
    
    % Apply fits
    Seg_1_fit = Fit_1(1 : i2 - i1 +1);
    Seg_2_fit = Fit_2(1 : TPCfg.fitextendednpts);
    
    % Calculate the slopes
    Seg_1_fitslope = diff(Seg_1_fit);
    Seg_2_fitslope = diff(Seg_2_fit);
    
    % Calculate an offset that occurred during the skip
    offset_skip = Seg_2(1) - Seg_1(end);
end

%% Grab output
if ~TPCfg.matchslopes
    TwoPoints = [median(Seg_1(end - TPCfg.npts + 1 : end)),...
        median(Seg_2(end - TPCfg.npts + 1 : end))];
else
    % Get the slope and match the point
    slope2find = Seg_1_fitslope(end);
    [~, matchpt] = min(abs(Seg_2_fitslope - slope2find));
    matchpt = matchpt + 1;
    
    % Get the two points
    if matchpt <= length(Seg_2)
        TwoPoints = [median(Seg_1(end - TPCfg.npts + 1 : end)),...
            median(Seg_2(matchpt - TPCfg.npts + 1 : end))];
    else
        TwoPoints = [median(Seg_1(end - TPCfg.npts + 1 : end)),...
            median(Seg_2_fit(matchpt - TPCfg.npts + 1 : end))];
    end
    
    % Include the offset
    if TPCfg.useoffset
        TwoPoints(2) = TwoPoints(2) - offset_skip;
    end
end

% Announce
fprintf('The two points are %3.2f and %3.2f.\n', ...
    TwoPoints(1), TwoPoints(2));

%% Save outputs
if TPCfg.matchslopes
    save(fullfile(filepath,filename_output_twopoints), 'TPCfg', 'TwoPoints',...
        'Seg_1', 'Seg_2', 'Seg_1_fit', 'Seg_2_fit', 'Seg_1_fitslope',...
        'Seg_2_fitslope', 'slope2find', 'matchpt', 'lskip', 'skipind');
else
    save(fullfile(filepath,filename_output_twopoints), 'TPCfg', 'TwoPoints',...
        'Seg_1', 'Seg_2', 'lskip', 'skipind');
end