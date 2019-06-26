%% Initialization
clear all

% Use filtered?
use_filtered = 0;

% Fit mode
fit_mode = 'linear'; % mean or median
%% IO
% common path
defaultpath = '\\anastasia\data\photometry';

% Work out outputpath
[filename2, filepath2] = uigetfile(fullfile(defaultpath , '*_preprocessed.mat'));
filename_output_fixed = [filename2(1:end-4), '_fixed.mat'];
load(fullfile(filepath2, filename2));

%% Grab points to ignore

% See if there are points in ram
if exist('n_ignorepts', 'var')
    if n_ignorepts > 0
        % Choose if redo points
        redo = questdlg('Redo points?', ...
            'Redo points', ...
            'Yes', 'No', 'Add', 'No');
        
        redo_or_not = strcmp(redo, 'Yes') || strcmp(redo, 'Add');
    end
else
    redo_or_not = true;
    redo = '';
end

if redo_or_not
    % Determine if using filtered or unfiltered data
    if use_filtered > 0
        ch1_to_fix = Ch1_filtered;
        ch2_to_fix = Ch2_filtered;
    else
        ch1_to_fix = ch1_data_table(:,2);
        ch2_to_fix = ch2_data_table(:,2);
    end

    if strcmp(redo, 'Add')

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
    
    % Grab points to be fixed
    figure(101)
    hplot = plot([ch1_to_fix, ch2_to_fix]);
    xlabel('Index')
    ylabel('Photodiode voltage (V)')
    
    % choose points
    choose_points = questdlg('Choose points?', ...
        'Choose points', ...
        'Yes', 'No', 'Yes');
    choose_points = strcmp(choose_points, 'Yes');
    
    % Grab the necessary figure handles
    figure(101)
    hTraces = get(101,'Children');

    while choose_points

        % Grab box
        boxui = imrect(gca);
%         boxui = imrect(gca, [length(ch1_to_fix)/2, 3.5, 1000, 1]);
        userbox = wait(boxui);
        delete(boxui)
        user_interval = round([userbox(1), userbox(1) + userbox(3)]);
        user_interval(1) = max(0, user_interval(1));
        user_interval(2) = min(length(ch1_to_fix), user_interval(2));

        % Add 1 point to ignore
        n_ignorepts = n_ignorepts + 1;
        ignorepoints(n_ignorepts, 1:2) = user_interval; %#ok<SAGROW>

        % Remove the points inbetween
        ch1_to_fix(user_interval(1):user_interval(2)) = nan;
        ch2_to_fix(user_interval(1):user_interval(2)) = nan;

        % Update traces
        hTraces.Children(end).YData = ch2_to_fix;
        hTraces.Children(end-1).YData = ch1_to_fix;
        

        % choose points
        choose_points = questdlg('Choose points?', ...
            'Choose points', ...
            'Yes','No', 'Yes');
        choose_points = strcmp(choose_points, 'Yes');
    end
else
    % Determine if using filtered or unfiltered data
    if use_filtered > 0
        ch1_to_fix = Ch1_filtered;
        ch2_to_fix = Ch2_filtered;
    else
        ch1_to_fix = ch1_data_table(:,2);
        ch2_to_fix = ch2_data_table(:,2);
    end
    
    for i = 1 : n_ignorepts
        % Remove the points inbetween
        ch1_to_fix(ignorepoints(i,1):ignorepoints(i,2)) = nan;
        ch2_to_fix(ignorepoints(i,1):ignorepoints(i,2)) = nan;
    end
    
    % Plot
    figure(101)
    hplot = plot([ch1_to_fix, ch2_to_fix]);
    xlabel('Index')
    ylabel('Photodiode voltage (V)')
end


%% Shift Ch2 to meet Ch1
% Find break points
intactpoints = chainfinder(~isnan(ch1_to_fix));


for i = 1 : size(intactpoints,1)
    % Grab indices
    ind1 = intactpoints(i,1);
    ind2 = intactpoints(i,1) + intactpoints(i,2) - 1;

    % Determine how much to shift
    switch fit_mode
        case 'mean'
            fitinfo = mean(ch2_to_fix(ind1:ind2)) - mean(ch1_to_fix(ind1:ind2));
            ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2) - fitinfo;
        case 'median'
            fitinfo = median(ch2_to_fix(ind1:ind2)) - median(ch1_to_fix(ind1:ind2));
            ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2) - fitinfo;
        case 'linear'
            fitinfo = polyfit(ch2_to_fix(ind1:ind2), ch1_to_fix(ind1:ind2), 1);
            ch2_to_fix(ind1:ind2) = ch2_to_fix(ind1:ind2) * fitinfo(1) + fitinfo(2);
    end
    
end

% Plot
figure(102)
plot([ch1_to_fix, ch2_to_fix])
xlabel('Index')
ylabel('Photodiode voltage (V)')

%% Filter
% Lowpass filter
d = fdesign.lowpass('Fp,Fst,Ap,Ast',7,10,0.5,40,100);
Hd = design(d,'equiripple');
% fvtool(Hd)

% Filter
ch1_fixed_filtered = filter(Hd,ch1_to_fix);
ch2_fixed_filtered = filter(Hd,ch2_to_fix);

% Perform subtraction
signal = ch1_fixed_filtered - ch2_fixed_filtered;


% Plot
figure(102)
plot((1 : n_points)'/freq/60, signal)
xlabel('Time(min)')
ylabel('Photodiode voltage (V)')

%% Clear and save
% % Clear data
% if exist('data', 'var')
%     clear data;
% end
% 
% % Clear time stamps
% if exist('timestamps', 'var')
%     clear timestamps;
% end

% Save
save(fullfile(filepath2,filename_output_fixed));