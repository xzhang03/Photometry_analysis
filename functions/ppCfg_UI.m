function hfig = ppCfg_UI(defaultpath)
% ppCfg_UI uses an ui to generate config for photometry preprocessing

%% Initial setting
if nargin < 1
    defaultpath = '';
end

% Apollo SCOpto
rigs.apollo.scp.name = 'Apollo SCP';
rigs.apollo.scp.mode = '1. Green sensor (+ blue opto)';
rigs.apollo.scp.data_channel = 1;
rigs.apollo.scp.data_channel2 = 99;
rigs.apollo.scp.opto_channel = 4;
rigs.apollo.scp.ch1_pulse_ind = 5;
rigs.apollo.scp.ch2_pulse_ind = 5;
rigs.apollo.scp.cam_channel = 7;
rigs.apollo.scp.ch1_pulse_thresh = 0.5;
rigs.apollo.scp.ch2_pulse_thresh = 0.5;
rigs.apollo.scp.optomode = true;
rigs.apollo.scp.tone_channel = 10; 
rigs.apollo.scp.lick_channel = 8; 
rigs.apollo.scp.ensure_channel = 9; 

% Apollo TCP
rigs.apollo.tcp.name = 'Apollo TCP';
rigs.apollo.tcp.mode = '2. Green + red sensor';
rigs.apollo.tcp.data_channel = 1;
rigs.apollo.tcp.data_channel2 = 2;
rigs.apollo.tcp.opto_channel = 99;
rigs.apollo.tcp.ch1_pulse_ind = 5;
rigs.apollo.tcp.ch2_pulse_ind = 6;
rigs.apollo.tcp.cam_channel = 7;
rigs.apollo.tcp.ch1_pulse_thresh = 0.5;
rigs.apollo.tcp.ch2_pulse_thresh = 0.5;
rigs.apollo.tcp.optomode = false;
rigs.apollo.tcp.tone_channel = 10; 
rigs.apollo.tcp.lick_channel = 8; 
rigs.apollo.tcp.ensure_channel = 9; 

% Apollo licks
rigs.apollo.licktrig.name = 'Apollo licks';
rigs.apollo.licktrig.mode = '3. Green + lick trig (+ red sensor)';
rigs.apollo.licktrig.data_channel = 1;
rigs.apollo.licktrig.data_channel2 = 2;
rigs.apollo.licktrig.opto_channel = 8;
rigs.apollo.licktrig.ch1_pulse_ind = 5;
rigs.apollo.licktrig.ch2_pulse_ind = 6;
rigs.apollo.licktrig.cam_channel = 7;
rigs.apollo.licktrig.ch1_pulse_thresh = 0.5;
rigs.apollo.licktrig.ch2_pulse_thresh = 0.5;
rigs.apollo.licktrig.optomode = true;
rigs.apollo.licktrig.tone_channel = 10; 
rigs.apollo.licktrig.lick_channel = 8; 
rigs.apollo.licktrig.ensure_channel = 9; 

% Artemis Optophoto
rigs.artemis.optophoto.name = 'Artemis Optophotometry';
rigs.artemis.optophoto.mode = '1. Green sensor + red stim';
rigs.artemis.optophoto.data_channel = 1;
rigs.artemis.optophoto.data_channel2 = 99;
rigs.artemis.optophoto.opto_channel = 6;
rigs.artemis.optophoto.ch1_pulse_ind = 5;
rigs.artemis.optophoto.ch2_pulse_ind = 5;
rigs.artemis.optophoto.cam_channel = 7;
rigs.artemis.optophoto.ch1_pulse_thresh = 0.5;
rigs.artemis.optophoto.ch2_pulse_thresh = 0.5;
rigs.artemis.optophoto.optomode = true;
rigs.artemis.optophoto.tone_channel = 10; 
rigs.artemis.optophoto.lick_channel = 8; 
rigs.artemis.optophoto.ensure_channel = 9; 

% Artemis photometry
rigs.artemis.photo.name = 'Artemis Photometry';
rigs.artemis.photo.mode = '2. Green sensor + food';
rigs.artemis.photo.data_channel = 1;
rigs.artemis.photo.data_channel2 = 99;
rigs.artemis.photo.opto_channel = 6;
rigs.artemis.photo.ch1_pulse_ind = 5;
rigs.artemis.photo.ch2_pulse_ind = 5;
rigs.artemis.photo.cam_channel = 7;
rigs.artemis.photo.ch1_pulse_thresh = 0.5;
rigs.artemis.photo.ch2_pulse_thresh = 0.5;
rigs.artemis.photo.optomode = true;
rigs.artemis.photo.tone_channel = 10; 
rigs.artemis.photo.lick_channel = 8; 
rigs.artemis.photo.ensure_channel = 9; 

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
rigs.cleopatra.tcp.lick_channel = 99; 
rigs.cleopatra.tcp.ensure_channel = 99; 
rigs.cleopatra.tcp.cam_channel = 99;

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
rigs.cleopatra.optophoto.lick_channel = 99; 
rigs.cleopatra.optophoto.ensure_channel = 99; 
rigs.cleopatra.optophoto.cam_channel = 99;

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
rigs.minerva.optophoto.lick_channel = 99; 
rigs.minerva.optophoto.ensure_channel = 99; 
rigs.minerva.optophoto.cam_channel = 99;

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
rigs.rbg.tcp.lick_channel = 99; 
rigs.rbg.tcp.ensure_channel = 99; 
rigs.rbg.tcp.cam_channel = 99;

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
rigs.rbg.optophoto.lick_channel = 99; 
rigs.rbg.optophoto.ensure_channel = 99; 
rigs.rbg.optophoto.cam_channel = 99;

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
rigs.rbg.scoptophoto.lick_channel = 99; 
rigs.rbg.scoptophoto.ensure_channel = 99; 
rigs.rbg.scoptophoto.cam_channel = 99;

% RBG scoptophoto (GCaMP + biPAC)
rigs.rbg.foodphoto.name = 'RBG GCaMP + food';
rigs.rbg.foodphoto.mode = '4. Green sensor (food channel as tone)';
rigs.rbg.foodphoto.data_channel = 1;
rigs.rbg.foodphoto.data_channel2 = 99;
rigs.rbg.foodphoto.opto_channel = 7;
rigs.rbg.foodphoto.ch1_pulse_ind = 2;
rigs.rbg.foodphoto.ch2_pulse_ind = 2;
rigs.rbg.foodphoto.ch1_pulse_thresh = 1;
rigs.rbg.foodphoto.ch2_pulse_thresh = 0.5;
rigs.rbg.foodphoto.optomode = true;
rigs.rbg.foodphoto.tone_channel = 4; 
rigs.rbg.foodphoto.lick_channel = 99; 
rigs.rbg.foodphoto.ensure_channel = 99; 
rigs.rbg.foodphoto.cam_channel = 99;

% Cleopatra tcp
rigs.roger.tcp.name = 'Roger TCP';
rigs.roger.tcp.mode = '1. Green sensor + 405 movement';
rigs.roger.tcp.data_channel = 1;
rigs.roger.tcp.data_channel2 = 99;
rigs.roger.tcp.opto_channel = 99;
rigs.roger.tcp.ch1_pulse_ind = 2;
rigs.roger.tcp.ch2_pulse_ind = 7;
rigs.roger.tcp.ch1_pulse_thresh = 2;
rigs.roger.tcp.ch2_pulse_thresh = 2;
rigs.roger.tcp.optomode = false;
rigs.roger.tcp.tone_channel = 99; 
rigs.roger.tcp.lick_channel = 99; 
rigs.roger.tcp.ensure_channel = 99; 
rigs.roger.tcp.cam_channel = 99;

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
hfig = figure('position', [300 200 250 550], 'MenuBar', 'none', 'ToolBar', 'none');
topleft = [20 520 0 0];
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

% Cam pulses
uicontrol(hfig, 'Style', 'text', 'String', 'Cam', 'Position', topleft + [minorx*2 2*majory 50 20]);
hc = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).cam_channel,...
    'Position', topleft + [minorx*2 2*majory+minory 50 20], 'callback', @updaterigsfromboxes);

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
uicontrol(hfig, 'Style', 'text', 'String', 'Tone Pulse', 'Position', topleft + [0 5*majory 60 20]);
hoc = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).tone_channel,...
    'Position', topleft + [0 5*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Lick channel
uicontrol(hfig, 'Style', 'text', 'String', 'Lick Pulse', 'Position', topleft + [minorx 5*majory 60 20]);
hlc = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).lick_channel,...
    'Position', topleft + [minorx 5*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Ensure channel
uicontrol(hfig, 'Style', 'text', 'String', 'Ensure Pulse', 'Position', topleft + [minorx*2 5*majory 70 20]);
hec = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ensure_channel,...
    'Position', topleft + [minorx*2 5*majory+minory 50 20], 'callback', @updaterigsfromboxes);

% Rare items
ri = 6;

% Expts
uicontrol(hfig, 'Style', 'text', 'String', '3. Rare changes: ', 'Position', topleft + [0 ri*majory 200 20]);

% Filter stim
hfswitch = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Stim Filter Hz:', 'Position', topleft + ...
    [0 ri*majory+minory 90 20], 'Value', filt_stim, 'Callback', @stimfiltercheck);
hf1 = uicontrol(hfig, 'Style', 'edit', 'String', stim_filt_range(1), 'Position', ...
    topleft + [minorx+20 ri*majory+minory 20 20]);
uicontrol(hfig, 'Style', 'text', 'String', '-', 'Position', topleft + ...
    [minorx+40 ri*majory+minory 10 20]);
hf2 = uicontrol(hfig, 'Style', 'edit', 'String', stim_filt_range(2), 'Position', ...
    topleft + [minorx+50 ri*majory+minory 20 20]);
if filt_stim
    hf1.Enable = 'on';
    hf2.Enable = 'on';
else
    hf1.Enable = 'off';
    hf2.Enable = 'off';
end
      
% Filter notch
hfnotch = uicontrol(hfig, 'Style', 'radiobutton', 'String', '60Hz Filter', 'Position', topleft + ...
    [minorx+80 ri*majory+minory 90 20], 'Value', use_fnotch_60);

% Blackout window
uicontrol(hfig, 'Style', 'text', 'String', 'Blackout Win', 'Position', topleft + [0 ri*majory+2.5*minory 65 20]);
hbw = uicontrol(hfig, 'Style', 'edit', 'String', blackout_window, 'Position', ...
    topleft + [0 ri*majory+3.5*minory 70 20]);

% Ambient light window
uicontrol(hfig, 'Style', 'text', 'String', 'Ambient Win', 'Position', topleft + [75 ri*majory+2.5*minory 65 20]);
ham = uicontrol(hfig, 'Style', 'edit', 'String', Ambientpts, 'Position', ...
    topleft + [75 ri*majory+3.5*minory 70 20]);

% Data freq
uicontrol(hfig, 'Style', 'text', 'String', 'Data Freq', 'Position', topleft + [150 ri*majory+2.5*minory 65 20]);
hfreq = uicontrol(hfig, 'Style', 'edit', 'String', freq, 'Position', ...
    topleft + [150 ri*majory+3.5*minory 70 20]);

% Buttons
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Load Setting', 'Position', ...
    topleft + [0 (ri+2)*majory 70 30], 'Callback', @loadsetting);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Done', 'Position', ...
    topleft + [75 (ri+2)*majory 70 30], 'Callback', @done);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', ...
    topleft + [150 (ri+2)*majory 70 30], 'Callback', @cancel);

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
        hlc.String = rigs.(rigsel).(exptsel).lick_channel;
        hec.String = rigs.(rigsel).(exptsel).ensure_channel;
        hc.String = rigs.(rigsel).(exptsel).cam_channel;
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
        rigs.(rigsel).(exptsel).lick_channel = str2double(hlc.String);
        rigs.(rigsel).(exptsel).ensure_channel = str2double(hec.String);
        rigs.(rigsel).(exptsel).cam_channel = str2double(hc.String);
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
            'ch2_pulse_thresh', rigs.(rigsel).(exptsel).ch2_pulse_thresh, 'cam_channel', str2double(hc.String),...
            'filt_stim', hfswitch.Value, 'stim_filt_range', [str2double(hf1.String), str2double(hf2.String)],...
            'use_fnotch_60', hfnotch.Value,'fnotch_60', fnotch_60, 'blackout_window', str2double(hbw.String),...
            'freq', str2double(hfreq.String), 'Ambientpts', str2double(ham.String), 'tone_channel', str2double(hoc.String),...
            'lick_channel', str2double(hlc.String), 'ensure_channel', str2double(hec.String), 'rigs', rigs);
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
        hlc.String = num2str(ppCfg_load.lick_channel);
        hec.String = num2str(ppCfg_load.ensure_channel);
        hc.String = num2str(ppCfg_load.cam_channel);

        PULSE_SIM_MODE = ppCfg_load.PULSE_SIM_MODE;
        fnotch_60 = ppCfg_load.fnotch_60;
    end


end

