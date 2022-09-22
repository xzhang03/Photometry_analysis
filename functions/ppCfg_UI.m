function hfig = ppCfg_UI(defaultpath)
% ppCfg_UI uses an ui to generate config for photometry preprocessing

%% Initial setting
if nargin < 1
    defaultpath = '';
end

% Cleopatra tcp
rigs.cleopatra.tcp.name = 'Cleopatra TCP';
rigs.cleopatra.tcp.mode = '1. Green sensor + 405 movement';
rigs.cleopatra.tcp.data_channel = 1;
rigs.cleopatra.tcp.data_channel2 = 99;
rigs.cleopatra.tcp.opto_channel = 99;
rigs.cleopatra.tcp.ch1_pulse_ind = 2;
rigs.cleopatra.tcp.ch2_pulse_ind = 9;
rigs.cleopatra.tcp.ch1_pulse_thresh = 2;
rigs.cleopatra.tcp.ch2_pulse_thresh = 0.5;
rigs.cleopatra.tcp.optomode = false;
rigs.cleopatra.tcp.tone_channel = 99; 

% Cleopatra optophoto (Green Sensor + Red Stim)
rigs.cleopatra.optophoto.name = 'Cleopatra GCaMP + Chrimson';
rigs.cleopatra.optophoto.mode = '2. Green sensor + Red stim';
rigs.cleopatra.optophoto.data_channel = 3;
rigs.cleopatra.optophoto.data_channel2 = 99;
rigs.cleopatra.optophoto.opto_channel = 9;
rigs.cleopatra.optophoto.ch1_pulse_ind = 2;
rigs.cleopatra.optophoto.ch2_pulse_ind = 2;
rigs.cleopatra.optophoto.ch1_pulse_thresh = 1;
rigs.cleopatra.optophoto.ch2_pulse_thresh = 0.5;
rigs.cleopatra.optophoto.optomode = true;
rigs.cleopatra.optophoto.tone_channel = 99; 

% Minerva optophoto
rigs.minerva.optophoto.name = 'Minerva placeholder';
rigs.minerva.optophoto.mode = '1. placeholder';
rigs.minerva.optophoto.data_channel = 99;
rigs.minerva.optophoto.data_channel2 = 99;
rigs.minerva.optophoto.opto_channel = 99;
rigs.minerva.optophoto.ch1_pulse_ind = 99;
rigs.minerva.optophoto.ch2_pulse_ind = 99;
rigs.minerva.optophoto.ch1_pulse_thresh = 99;
rigs.minerva.optophoto.ch2_pulse_thresh = 99;
rigs.minerva.optophoto.optomode = true;
rigs.minerva.optophoto.tone_channel = 99; 

% RBG tcp (GCaMP + RFP)
rigs.rbg.tcp.name = 'RBG GCaMP + RFP';
rigs.rbg.tcp.mode = '1. Green sensor + Red motion';
rigs.rbg.tcp.data_channel = 1;
rigs.rbg.tcp.data_channel2 = 5;
rigs.rbg.tcp.opto_channel = 99;
rigs.rbg.tcp.ch1_pulse_ind = 2;
rigs.rbg.tcp.ch2_pulse_ind = 7;
rigs.rbg.tcp.ch1_pulse_thresh = 2;
rigs.rbg.tcp.ch2_pulse_thresh = 2;
rigs.rbg.tcp.optomode = false;
rigs.rbg.tcp.tone_channel = 8; 

% RBG optophoto (RCaMP + ChR2)
rigs.rbg.optophoto.name = 'RBG RCaMP + ChR2';
rigs.rbg.optophoto.mode = '2. Red sensor + Blue stim';
rigs.rbg.optophoto.data_channel = 5;
rigs.rbg.optophoto.data_channel2 = 99;
rigs.rbg.optophoto.opto_channel = 7;
rigs.rbg.optophoto.ch1_pulse_ind = 2;
rigs.rbg.optophoto.ch2_pulse_ind = 2;
rigs.rbg.optophoto.ch1_pulse_thresh = 1;
rigs.rbg.optophoto.ch2_pulse_thresh = 0.5;
rigs.rbg.optophoto.optomode = true;
rigs.rbg.optophoto.tone_channel = 8; 

% RBG scoptophoto (GCaMP + biPAC)
rigs.rbg.scoptophoto.name = 'RBG GCaMP + biPAC';
rigs.rbg.scoptophoto.mode = '3. Green sensor + Blue stim';
rigs.rbg.scoptophoto.data_channel = 1;
rigs.rbg.scoptophoto.data_channel2 = 99;
rigs.rbg.scoptophoto.opto_channel = 7;
rigs.rbg.scoptophoto.ch1_pulse_ind = 2;
rigs.rbg.scoptophoto.ch2_pulse_ind = 2;
rigs.rbg.scoptophoto.ch1_pulse_thresh = 1;
rigs.rbg.scoptophoto.ch2_pulse_thresh = 0.5;
rigs.rbg.scoptophoto.optomode = true;
rigs.rbg.scoptophoto.tone_channel = 8; 

% Check if config exist
tf = evalin('base','exist(''ppCfg'')');

if tf
    ppCfg = evalin('base', 'ppCfg');
    rignamess = fieldnames(rigs);
    rigsel = ppCfg.rig;
    
    [expts, exptns] = listexpts(rigs.(rigsel));
    exptsel = ppCfg.mode;
    
    filt_stim = ppCfg.filt_stim;
    stim_filt_range = ppCfg.stim_filt_range;
    use_fnotch_60 = ppCfg.use_fnotch_60;
    fnotch_60 = ppCfg.fnotch_60;
    blackout_window = ppCfg.blackout_window;
    freq = ppCfg.freq;
    Ambientpts = ppCfg.Ambientpts;
    PULSE_SIM_MODE = ppCfg.PULSE_SIM_MODE;
else
    % Filter out stim artifact
    filt_stim = false;
    stim_filt_range = [9 11]; % Notch filter to remove stim artifacts (in Hz)

    % Use 60 Hz filter
    use_fnotch_60 = true;
    fnotch_60 = [59 61];

    % [ Black out points ] This will change the values that come out of your analysis!
    blackout_window = 9; % Ignore the first X points within each pulse due to capacitated currents (9 for 2500 Hz)

    % Channel and frequency data
    freq = 50; % Sampling rate after downsampling (i.e., pulse rate of each channel in Hz)

    % Shoulder size for subtraction
    % The number of points before the onset of each pulse that can be averaged
    % and subtracted off as ambient background. Set to 0 to skip this step
    Ambientpts = 0;

    % No pulse info (and no pulses are used during photometry)
    PULSE_SIM_MODE = false;
    
    rignamess = fieldnames(rigs);
    rigsel = rignamess{1};
    
    [expts, exptns] = listexpts(rigs.(rigsel));
    exptsel = expts{1};
end
%% UI
hfig = figure('position', [300 200 250 480], 'MenuBar', 'none', 'ToolBar', 'none');
topleft = [20 450 0 0];
minory = -20;
majory = -60;
minorx = 70;

% Rig
uicontrol(hfig, 'Style', 'text', 'String', '1. Select a rig: ', 'Position', topleft + [0 0 200 20]);
hrigsel = uicontrol(hfig, 'Style', 'popup', 'String', rignamess, 'Position', topleft + [0, minory, 200, 20], ...
    'Callback', @getexpts, 'Value', find(strcmp(rignamess, rigsel)));

% Expts
uicontrol(hfig, 'Style', 'text', 'String', '2. Select an experiment: ', 'Position', topleft + [0 majory 200 20]);
hexptsel = uicontrol(hfig, 'Style', 'popup', 'String', exptns, 'Position', topleft + [0, majory + minory, 200, 20], ...
    'Callback', @getboxes, 'Value', find(strcmp(expts, exptsel)));

% Boxes
% Ch1 data
uicontrol(hfig, 'Style', 'text', 'String', 'Ch1 Data', 'Position', topleft + [0 2*majory 50 20]);
hd1 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).data_channel,...
    'Position', topleft + [0 2*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Ch2 data
uicontrol(hfig, 'Style', 'text', 'String', 'Ch2 Data', 'Position', topleft + [minorx 2*majory 50 20]);
hd2 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).data_channel2,...
    'Position', topleft + [minorx 2*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Ch1 in
uicontrol(hfig, 'Style', 'text', 'String', 'Ch1 Pulse', 'Position', topleft + [0 3*majory 50 20]);
hi1 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ch1_pulse_ind,...
    'Position', topleft + [0 3*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Ch2 in
uicontrol(hfig, 'Style', 'text', 'String', 'Ch2 Pulse', 'Position', topleft + [minorx 3*majory 50 20]);
hi2 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ch2_pulse_ind,...
    'Position', topleft + [minorx 3*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Opto
uicontrol(hfig, 'Style', 'text', 'String', 'Opto Pulse', 'Position', topleft + [minorx*2 3*majory 60 20]);
hio = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).opto_channel,...
    'Position', topleft + [minorx*2 3*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Ch1 thresh
uicontrol(hfig, 'Style', 'text', 'String', 'Ch1 Thresh', 'Position', topleft + [0 4*majory 60 20]);
ht1 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ch1_pulse_thresh,...
    'Position', topleft + [0 4*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Ch2 thresh
uicontrol(hfig, 'Style', 'text', 'String', 'Ch2 Thresh', 'Position', topleft + [minorx 4*majory 60 20]);
ht2 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ch2_pulse_thresh,...
    'Position', topleft + [minorx 4*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Tone channel
uicontrol(hfig, 'Style', 'text', 'String', 'Tone Pulse', 'Position', topleft + [minorx*2 4*majory 60 20]);
hoc = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).tone_channel,...
    'Position', topleft + [minorx*2 4*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Rare items
% Expts
uicontrol(hfig, 'Style', 'text', 'String', '3. Rare changes: ', 'Position', topleft + [0 5*majory 200 20]);

% Filter stim
hfswitch = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Stim Filter Hz:', 'Position', topleft + ...
    [0 5*majory+minory 90 20], 'Value', filt_stim, 'Callback', @stimfiltercheck);
hf1 = uicontrol(hfig, 'Style', 'edit', 'String', stim_filt_range(1), 'Position', ...
    topleft + [minorx+20 5*majory+minory 20 20]);
uicontrol(hfig, 'Style', 'text', 'String', '-', 'Position', topleft + ...
    [minorx+40 5*majory+minory 10 20]);
hf2 = uicontrol(hfig, 'Style', 'edit', 'String', stim_filt_range(2), 'Position', ...
    topleft + [minorx+50 5*majory+minory 20 20]);
if filt_stim
    hf1.Enable = 'on';
    hf2.Enable = 'on';
else
    hf1.Enable = 'off';
    hf2.Enable = 'off';
end
      
% Filter notch
hfnotch = uicontrol(hfig, 'Style', 'radiobutton', 'String', '60Hz Filter', 'Position', topleft + ...
    [minorx+80 5*majory+minory 90 20], 'Value', use_fnotch_60);

% Blackout window
uicontrol(hfig, 'Style', 'text', 'String', 'Blackout Win', 'Position', topleft + [0 5*majory+2.5*minory 65 20]);
hbw = uicontrol(hfig, 'Style', 'edit', 'String', blackout_window, 'Position', ...
    topleft + [0 5*majory+3.5*minory 70 20]);

% Ambient light window
uicontrol(hfig, 'Style', 'text', 'String', 'Ambient Win', 'Position', topleft + [75 5*majory+2.5*minory 65 20]);
ham = uicontrol(hfig, 'Style', 'edit', 'String', Ambientpts, 'Position', ...
    topleft + [75 5*majory+3.5*minory 70 20]);

% Data freq
uicontrol(hfig, 'Style', 'text', 'String', 'Data Freq', 'Position', topleft + [150 5*majory+2.5*minory 65 20]);
hfreq = uicontrol(hfig, 'Style', 'edit', 'String', freq, 'Position', ...
    topleft + [150 5*majory+3.5*minory 70 20]);

% Buttons
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Load Setting', 'Position', ...
    topleft + [0 7*majory 70 30], 'Callback', @loadsetting);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Done', 'Position', ...
    topleft + [75 7*majory 70 30], 'Callback', @done);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', ...
    topleft + [150 7*majory 70 30], 'Callback', @cancel);

%% Call backs
% When a rig is selected
    function getexpts(src, ~)
        rigsel = rignamess{src.Value};
        [expts, exptns] = listexpts(rigs.(rigsel));
        hexptsel.String = exptns;
        hexptsel.Value = 1;
        exptsel = expts{hexptsel.Value};
        updateboxes();
    end

% List experiments for rig
    function [expts, exptns] = listexpts(inputstruct)
        expts = fieldnames(inputstruct);
        exptns = cell(size(expts));
        for i = 1 : length(expts)
            exptns{i} = inputstruct.(expts{i}).mode;
        end
    end

% When an expt is selected
    function getboxes(src, ~)
        exptsel = expts{src.Value};
        updateboxes();
    end

% Update box values
    function updateboxes()
        hd1.String = rigs.(rigsel).(exptsel).data_channel;
        hd2.String = rigs.(rigsel).(exptsel).data_channel2;
        hi1.String = rigs.(rigsel).(exptsel).ch1_pulse_ind;
        hi2.String = rigs.(rigsel).(exptsel).ch2_pulse_ind;
        hio.String = rigs.(rigsel).(exptsel).opto_channel;
        ht1.String = rigs.(rigsel).(exptsel).ch1_pulse_thresh;
        ht2.String = rigs.(rigsel).(exptsel).ch2_pulse_thresh;
        hoc.String = rigs.(rigsel).(exptsel).tone_channel;
    end

% Update rig values from boxes
    function updaterigsfromboxes(~, ~)
        rigs.(rigsel).(exptsel).data_channel = str2double(hd1.String);
        rigs.(rigsel).(exptsel).data_channel2 = str2double(hd2.String);
        rigs.(rigsel).(exptsel).ch1_pulse_ind = str2double(hi1.String);
        rigs.(rigsel).(exptsel).ch2_pulse_ind = str2double(hi2.String);
        rigs.(rigsel).(exptsel).opto_channel = str2double(hio.String);
        rigs.(rigsel).(exptsel).ch1_pulse_thresh = str2double(ht1.String);
        rigs.(rigsel).(exptsel).ch2_pulse_thresh = str2double(ht2.String);
        rigs.(rigsel).(exptsel).tone_channel = str2double(hoc.String);
    end

% Stim filter check
    function stimfiltercheck(src,~)
        if src.Value
            hf1.Enable = 'on';
            hf2.Enable = 'on';
        else
            hf1.Enable = 'off';
            hf2.Enable = 'off';
        end
    end

% Cancel
    function cancel(~,~)
        close(hfig);
    end

% Done
    function done(~,~)
        ppCfg = struct('rig', rigsel, 'mode', exptsel,...
            'OPTO_MODE', rigs.(rigsel).(exptsel).optomode, 'PULSE_SIM_MODE', PULSE_SIM_MODE,...
            'data_channel', rigs.(rigsel).(exptsel).data_channel, 'data_channel2', rigs.(rigsel).(exptsel).data_channel2,...
            'ch1_pulse_ind', rigs.(rigsel).(exptsel).ch1_pulse_ind, 'ch2_pulse_ind', rigs.(rigsel).(exptsel).ch2_pulse_ind,...
            'opto_channel', rigs.(rigsel).(exptsel).opto_channel, 'ch1_pulse_thresh', rigs.(rigsel).(exptsel).ch1_pulse_thresh,...
            'ch2_pulse_thresh', rigs.(rigsel).(exptsel).ch2_pulse_thresh, ...
            'filt_stim', hfswitch.Value, 'stim_filt_range', [str2double(hf1.String), str2double(hf2.String)],...
            'use_fnotch_60', hfnotch.Value,'fnotch_60', fnotch_60, 'blackout_window', str2double(hbw.String),...
            'freq', str2double(hfreq.String), 'Ambientpts', str2double(ham.String), 'tone_channel', str2double(hoc.String),...
            'rigs', rigs);
        assignin('base', 'ppCfg', ppCfg)
        close(hfig);
    end

% Load setting
    function loadsetting(~,~)
        [filename, filepath] = uigetfile(fullfile(defaultpath , '*_preprocessed.mat'));
        ppCfg_load = load(fullfile(filepath, filename), 'ppCfg');
        ppCfg_load = ppCfg_load.ppCfg;
        if isfield(ppCfg_load, 'rigs')
            rigs = ppCfg_load.rigs;
        end
        rigsel = ppCfg_load.rig;
        exptsel = ppCfg_load.mode;
                
        hrigsel.Value = find(strcmp(rignamess, rigsel));
        [expts, exptns] = listexpts(rigs.(rigsel));
        hexptsel.String = exptns;
        hexptsel.Value = find(strcmp(expts, exptsel));
        updateboxes();
        
        hfswitch.Value = ppCfg_load.filt_stim;
        hf1.String = num2str(ppCfg_load.stim_filt_range(1));
        hf2.String = num2str(ppCfg_load.stim_filt_range(2));
        hfnotch.Value = ppCfg_load.use_fnotch_60;
        hbw.String = num2str(ppCfg_load.blackout_window);
        hfreq.String = num2str(ppCfg_load.freq);
        ham.String = num2str(ppCfg_load.Ambientpts);
        hoc.String = num2str(ppCfg_load.tone_channel);
        
        PULSE_SIM_MODE = ppCfg_load.PULSE_SIM_MODE;
        fnotch_60 = ppCfg_load.fnotch_60;
    end


end

