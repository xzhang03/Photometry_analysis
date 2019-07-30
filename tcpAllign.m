%% Initialization
% Stephen Zhang 2019/07/30
clear

% Add subfolder
addpath('functions');

% ============================= General info ==============================
% Quiet mode? Just doing its job and no fuss.
QuietMode = false;
%
% Use filtered traces that are passed from preprocessing?
AllignCfg.use_filtered = false;
%
% Use filtered traces that are passed from preprocessing?
AllignCfg.lockinused = false;
AllignCfg.lockin_Ch1 = 1;
AllignCfg.lockin_Ch2 = 3;

% ============================ Pre-filter info ============================
%
% This filter is used for allignment only and will not be used to get the
% final trace.
AllignCfg.useprefilter = true; % On?
AllignCfg.prefilterFreq = 8; % Pre-filter frequency?

% ============================ Pre-smooth info ============================
%
% This pre-smooth step is used for allignment only and will not be used to
% get the final trace
AllignCfg.usepresmooth = true; % On?
AllignCfg.presmoothwindow = 10; % Window size for smoothing

% =================== Flatten info (single exponential) ===================
%
% This flatten step can be used either before or after the allignment to
% the two channels. If used either before or after, the flattened results
% will be used in the final trace. If you are only using parts of the trace
% to allign, you should set this to either 'post_flatten' or 'none';
AllignCfg.flatten_mode = 'post_flatten';

% =============================== Fit mode ================================
%
% 1. 'mean': Adjust the DC shift of Ch2 to match the mean of Ch1
% 2. 'median': Adjust the DC shift of Ch2 to match the median of Ch1
% 3. 'mean_scaling': Multiply Ch2 by a gain factor that is the ratio of the
% means of the two channels (Mean_1 / Mean_2)
% 4. 'linear': Linearly fit Ch2 to Ch1 (Ch2_new = Ch2_old * a + b)
% 5. 'linear_shift_ch1': Linearly fit Ch1 to Ch2 (Ch1_new = Ch1_old * a + b)
% 6. 'ratiometric': No fitting, just Ch1 ./ Ch2
AllignCfg.fit_mode = 'linear'; 

% ============================ Post-filter info ===========================
%
% This filter will be used to filter the two channels
AllignCfg.usepostfilter = true; % On?
AllignCfg.postfilterFreq = 8; % Post-filter frequency?

%% IO
% common path
defaultpath = '\\anastasia\data\photometry';

% Work out outputpath
if AllignCfg.lockinused
    % If used lock-in
    [filename2, filepath2] =...
        uigetfile(fullfile(defaultpath , '*.mat'));
else
    % No lock-in
    [filename2, filepath2] =...
        uigetfile(fullfile(defaultpath , '*_preprocessed.mat'));
end

filename_output_fixed = [filename2(1:end-4), '_fixed.mat'];
load(fullfile(filepath2, filename2));


%% Apply pre filters and grab points to ignore
% See if there are breakpoints in ram
if exist('n_ignorepts', 'var')
    if n_ignorepts > 0
        % Choose if redo points
        redo = questdlg('Redo break points?', ...
            'Redo points', ...
            'Yes', 'No', 'Add', 'No');
        
        redo_or_not = strcmp(redo, 'Yes') || strcmp(redo, 'Add');
    end
else
    redo_or_not = true;
    redo = '';
end

if ~QuietMode
    % Say something
    disp('Start processing...')
end

if AllignCfg.lockinused
    % Using lock-in
    if ~QuietMode
        % Say something
        disp('Using raw data from lock-in')
    end
    
    ch1_to_fix = data(AllignCfg.lockin_Ch1, :);
    ch2_to_fix = data(AllignCfg.lockin_Ch2, :);

elseif AllignCfg.use_filtered
    % Determine if using filtered or unfiltered data
    if ~QuietMode
        % Say something
        disp('Using filtered data from preprocess')
    end

    ch1_to_fix = Ch1_filtered;
    ch2_to_fix = Ch2_filtered;
else
    if ~QuietMode
        % Say something
        disp('Using raw data from preprocess')
    end
    ch1_to_fix = ch1_data_table(:,2);
    ch2_to_fix = ch2_data_table(:,2);
end

% If no redo or add more points, first applying the existing break points
if strcmp(redo, 'Add') || strcmp(redo, 'No')
    for i = 1 : n_ignorepts
        % Remove the points inbetween
        ch1_to_fix(ignorepoints(i,1):ignorepoints(i,2)) = nan;
        ch2_to_fix(ignorepoints(i,1):ignorepoints(i,2)) = nan;
    end
else
    % Initialize
    ignorepoints = [];
    n_ignorepts = 0;
end

% Pre-flatten if needed
if strcmpi(AllignCfg.flatten_mode, 'pre_flatten')
    if ~QuietMode
        % Say something
        disp('Pre-flattening')
    end

    % Flatten
    ch1_to_fix = tcpFlatten(ch1_to_fix, n_points);
    ch2_to_fix = tcpFlatten(ch2_to_fix, n_points);
end
    
% Prepare a copy of the traces just for allignment
ch1_for_fitting = ch1_to_fix;
ch2_for_fitting = ch2_to_fix;

% Pre-filter if so chosen
if AllignCfg.useprefilter
    if ~QuietMode
        % Say something
        disp('Pre-filtering')
    end

    % Filter
    ch1_for_fitting = tcpLPfilter(ch1_for_fitting,...
        AllignCfg.prefilterFreq, freq, 1);
    ch2_for_fitting = tcpLPfilter(ch2_for_fitting,...
        AllignCfg.prefilterFreq, freq, 1);
    
    % Remove the first 50 points if prefiltering
    ch1_for_fitting(1:50) = NaN;
    ch2_for_fitting(1:50) = NaN;
end

% Pre-smooth if so chosen
if AllignCfg.usepresmooth
    if ~QuietMode
        % Say something
        disp('Pre-smoothing')
    end

    % Apply smoothing
    ch1_for_fitting = smooth(ch1_for_fitting, ...
        AllignCfg.presmoothwindow, 'moving');
    ch2_for_fitting = smooth(ch2_for_fitting, ...
        AllignCfg.presmoothwindow, 'moving');
end

% Plot
figure(101)
hplot = plot([ch1_for_fitting, ch2_for_fitting]);
xlabel('Index')
ylabel('Photodiode voltage (V)')
hTraces = get(101,'Children');

% Main process
if redo_or_not
    
    % choose points
    fitting_segments = questdlg('Which parts to fit?', ...
        'Choose parts', ...
        'All', 'A segment', 'Breakpoints', 'All');

    
    % This is the removing points mode
    choose_points = strcmp(fitting_segments, 'Breakpoints');
    while choose_points
        % Get back to figure
        figure(101)
        
        % Grab box
        if ~QuietMode
            disp('Please draw a box and double click inside')
        end
        boxui = imrect(gca);
        userbox = wait(boxui);
        delete(boxui)
        user_interval = round([userbox(1), userbox(1) + userbox(3)]);
        user_interval(1) = max(1, user_interval(1));
        user_interval(2) = min(length(ch1_for_fitting), user_interval(2));

        % Add 1 point to ignore
        n_ignorepts = n_ignorepts + 1;
        ignorepoints(n_ignorepts, 1:2) = user_interval; %#ok<SAGROW>

        % Remove the points inbetween
        ch1_for_fitting(user_interval(1):user_interval(2)) = nan;
        ch2_for_fitting(user_interval(1):user_interval(2)) = nan;
        
        % Remove the points in the actual signal as well
        ch1_to_fix(user_interval(1):user_interval(2)) = nan;
        ch2_to_fix(user_interval(1):user_interval(2)) = nan;
        
        % Update traces
        hTraces.Children(2).YData = ch1_for_fitting;
        hTraces.Children(1).YData = ch2_for_fitting;
        
        % choose points
        choose_points = questdlg('Choose more points?', ...
            'Choose more points', ...
            'Yes','No', 'Yes');
        choose_points = strcmp(choose_points, 'Yes');
    end
    
    % This is the using-one-segment mode
    if strcmp(fitting_segments, 'A segment')
        % Get to the figure
        figure(101)
        
        % Grab box
        if ~QuietMode
        	disp('Please draw a box and double click inside')
        end
        boxui = imrect(gca);
        userbox = wait(boxui);
        delete(boxui)
        user_interval = round([userbox(1), userbox(1) + userbox(3)]);
        user_interval(1) = max(1, user_interval(1));
        user_interval(2) = min(length(ch1_for_fitting), user_interval(2));
        
        % Only keep the points inbetween
        ch1_for_fitting = ch1_for_fitting(user_interval(1):user_interval(2));
        ch2_for_fitting = ch2_for_fitting(user_interval(1):user_interval(2));

        % Update traces
        hTraces.Children(2).YData = ch1_for_fitting;
        hTraces.Children(1).YData = ch2_for_fitting;
        
    end
end

close(101)

%% Shift a channel to meet the other channel
% Find break points
intactpoints = chainfinder(~isnan(ch1_for_fitting));

% Display fitting mode
if ~QuietMode
    disp(['Fitting mode: ', AllignCfg.fit_mode]);
end

for i = 1 : size(intactpoints,1)
    % Grab indices
    ind1 = intactpoints(i,1);
    ind2 = intactpoints(i,1) + intactpoints(i,2) - 1;

    % Determine how much to shift
    switch AllignCfg.fit_mode
        case 'mean'
            fitinfo = mean(ch2_for_fitting(ind1:ind2)) - mean(ch1_for_fitting(ind1:ind2));
            ch2_for_fitting(ind1:ind2) = ch2_for_fitting(ind1:ind2) - fitinfo;
            
            % Apply to the actual trace
            if strcmp(fitting_segments, 'A segment')
                ch2_to_fix = ch2_to_fix - fitinfo;
            else
                ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2) - fitinfo;
            end
            
        case 'mean_scaling'
            fitinfo = mean(ch1_for_fitting(ind1:ind2) / mean(ch2_for_fitting(ind1:ind2)));
            ch2_for_fitting(ind1:ind2) = ch2_for_fitting(ind1:ind2) * fitinfo;
            
            % Apply to the actual trace
            if strcmp(fitting_segments, 'A segment')
                ch2_to_fix = ch2_to_fix * fitinfo;
            else
                ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2) * fitinfo;                
            end
            
            
        case 'median'
            fitinfo = median(ch2_for_fitting(ind1:ind2)) - median(ch1_for_fitting(ind1:ind2));
            ch2_for_fitting(ind1:ind2) = ch2_for_fitting(ind1:ind2) - fitinfo;
            
            % Apply to the actual trace
            if strcmp(fitting_segments, 'A segment')
                ch2_to_fix = ch2_to_fix - fitinfo;
            else
                ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2) - fitinfo;
            end
            
        case 'linear'
            fitinfo = polyfit(ch2_for_fitting(ind1:ind2), ch1_for_fitting(ind1:ind2), 1);
            ch2_for_fitting(ind1:ind2) = ch2_for_fitting(ind1:ind2) * fitinfo(1) + fitinfo(2);
            
            % Apply to the actual trace
            if strcmp(fitting_segments, 'A segment')
                ch2_to_fix = ch2_to_fix * fitinfo(1) + fitinfo(2);
            else
                ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2)...
                    * fitinfo(1) + fitinfo(2);
            end
            
        case 'linear_shift_ch1'
            fitinfo = polyfit(ch1_for_fitting(ind1:ind2), ch2_for_fitting(ind1:ind2), 1);
            ch1_for_fitting(ind1:ind2) = ch1_for_fitting(ind1:ind2) * fitinfo(1) + fitinfo(2);
            
            % Apply to the actual trace
            if strcmp(fitting_segments, 'A segment')
                ch1_to_fix = ch1_to_fix * fitinfo(1) + fitinfo(2);
            else
                ch1_to_fix(ind1:ind2) = ch1_to_fix(ind1:ind2)...
                    * fitinfo(1) + fitinfo(2);
            end
    end
    
end

if ~QuietMode
    % Plot
    figure(102)
    subplot(1,3,1)
    plot([ch1_for_fitting, ch2_for_fitting])
    xlabel('Index')
    ylabel('Photodiode voltage (V)')
    title('Region used to Allign')

    subplot(1,3,2)
    plot([ch1_to_fix, ch2_to_fix])
    xlabel('Index')
    ylabel('Photodiode voltage (V)')
    title('Alligned data')
end


%% Filter
% Post filter if needed
if AllignCfg.usepostfilter
    ch1_to_fix = tcpLPfilter(ch1_to_fix,...
        AllignCfg.postfilterFreq, freq, 1);
    ch2_to_fix = tcpLPfilter(ch2_to_fix,...
        AllignCfg.postfilterFreq, freq, 1);
end

% Post-flatten if needed
if strcmpi(AllignCfg.flatten_mode, 'post_flatten')
    % Say something
    disp('Post-flattening')

    % Flatten
    ch1_to_fix = tcpFlatten(ch1_to_fix, n_points);
    ch2_to_fix = tcpFlatten(ch2_to_fix, n_points);
end

if ~QuietMode
    % Plot
    figure(102)
    subplot(1,3,3)
    plot([ch1_to_fix, ch2_to_fix])
    xlabel('Index')
    ylabel('Photodiode voltage (V)')
    title('Post-processed data')
end

% Perform subtraction
if strcmpi(AllignCfg.fit_mode, 'ratiometric')
    signal = ch1_to_fix ./ ch2_to_fix;
else
    signal = ch1_to_fix - ch2_to_fix;
end

if ~QuietMode
    % Plot
    figure(103)
    plot((1 : n_points)'/freq, signal)
    xlabel('Time(s)')
    ylabel('Photodiode voltage (V)')
end

%% Clear and save
% Say where the data are saved
if ~QuietMode
    disp(['Saving data to: ', fullfile(filepath2,filename_output_fixed)]);
end

% Save
save(fullfile(filepath2,filename_output_fixed), 'AllignCfg', 'ch1_data_table', ...
    'Ch1_filtered', 'ch1_for_fitting', 'ch1_to_fix', 'ch2_data_table', ...
    'Ch2_filtered', 'ch2_for_fitting', 'ch2_to_fix', 'data', 'filename2',...
    'filepath2', 'filename_output_fixed', 'fitinfo', 'fitting_segments',...
    'freq', 'Fs', 'intactpoints', 'n_ignorepts', 'n_points', 'signal',...
    'SINGLE_CHANNEL_MODE', 'PULSE_SIM_MODE', 'timestamps');