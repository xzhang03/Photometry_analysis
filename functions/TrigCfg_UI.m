function hfig = TrigCfg_UI(defaultpath)
% ppCfg_UI uses an ui to generate config for photometry preprocessing

%% Initial setting
if nargin < 1
    defaultpath = '';
end

% Cleopatra optophoto (Green Sensor + Red Stim)
rigs.cleopatra.optophoto.name = 'Cleopatra GCaMP + Chrimson';
rigs.cleopatra.optophoto.mode = '1. Green sensor + Red stim';
rigs.cleopatra.optophoto.opto_channel = 9;
rigs.cleopatra.optophoto.ch1_pulse_ind = 2;
rigs.cleopatra.optophoto.minpulsewidth = 5;
rigs.cleopatra.optophoto.ch1_pulse_thresh = 1;
rigs.cleopatra.optophoto.optomode = true;
rigs.cleopatra.optophoto.camch = 4;
rigs.cleopatra.optophoto.lickch = 8;

% Minerva optophoto
rigs.minerva.optophoto.name = 'Minerva placeholder';
rigs.minerva.optophoto.mode = '1. placeholder';
rigs.minerva.optophoto.opto_channel = 99;
rigs.minerva.optophoto.ch1_pulse_ind = 99;
rigs.minerva.optophoto.minpulsewidth = 99;
rigs.minerva.optophoto.ch1_pulse_thresh = 99;
rigs.minerva.optophoto.optomode = true;
rigs.minerva.optophoto.camch = 99;
rigs.minerva.optophoto.lickch = 99;

% RBG optophoto (RCaMP + ChR2)
rigs.rbg.optophoto.name = 'RBG RCaMP + ChR2';
rigs.rbg.optophoto.mode = '1. Red sensor + Blue stim';
rigs.rbg.optophoto.opto_channel = 7;
rigs.rbg.optophoto.ch1_pulse_ind = 2;
rigs.rbg.optophoto.minpulsewidth = [];
rigs.rbg.optophoto.ch1_pulse_thresh = 1;
rigs.rbg.optophoto.optomode = true;
rigs.rbg.optophoto.camch = 3;
rigs.rbg.optophoto.lickch = 6;

% RBG scoptophoto (GCaMP + biPAC)
rigs.rbg.scoptophoto.name = 'RBG GCaMP + biPAC';
rigs.rbg.scoptophoto.mode = '2. Green sensor + Blue stim';
rigs.rbg.scoptophoto.opto_channel = 7;
rigs.rbg.scoptophoto.ch1_pulse_ind = 2;
rigs.rbg.scoptophoto.minpulsewidth = [];
rigs.rbg.scoptophoto.ch1_pulse_thresh = 1;
rigs.rbg.scoptophoto.optomode = true;
rigs.rbg.scoptophoto.camch = 3;
rigs.rbg.scoptophoto.lickch = 6;

% RBG scoptophoto (GCaMP + Audio)
rigs.rbg.audiophoto.name = 'RBG GCaMP + Audio Trigger';
rigs.rbg.audiophoto.mode = '3. Green sensor + Audio Trig';
rigs.rbg.audiophoto.opto_channel = 8;
rigs.rbg.audiophoto.ch1_pulse_ind = 2;
rigs.rbg.audiophoto.minpulsewidth = [];
rigs.rbg.audiophoto.ch1_pulse_thresh = 1;
rigs.rbg.audiophoto.optomode = true;
rigs.rbg.audiophoto.camch = 3;
rigs.rbg.audiophoto.lickch = 6;

% Check if config exist
tf = evalin('base','exist(''TrigCfg'')');

if tf 
    TrigCfg = evalin('base', 'TrigCfg');
    rignamess = fieldnames(rigs);
    rigsel = TrigCfg.rig;
    
    [expts, exptns] = listexpts(rigs.(rigsel));
    exptsel = TrigCfg.mode;

else
    % Flatten data
    TrigCfg.flatten_data = false;

    % Dff data
    TrigCfg.dff_data = false;
    TrigCfg.dff_win = 60; % In seconds
    TrigCfg.dff_prc = 10; % Percentile (10 excitation, 90 inhibition)

    % Window info (seconds before and after pulse onsets)
    TrigCfg.prew = 10; % 8
    TrigCfg.postw = 50; % 28

    % Interpolate out artifacts (problem with small NIDAQs)
    TrigCfg.Remove_artifacts = false;
    TrigCfg.artifact_ch = [4, 8];

    % GLM regress out artifacts
    TrigCfg.GLM_artifacts = true;
    TrigCfg.GLM_ch = 6;

    % The minimal number of seconds between pulses that are still in the same
    % train
    TrigCfg.trainlength_threshold = 5;

    % Suffix (for making multiple trigger files)
    TrigCfg.suffix = '';

    % Debugging variable (do not change)
    TrigCfg.DebugMode = false;
    if TrigCfg.DebugMode
        TrigCfg.opto_on_offset = 1; % In seconds
    end
    
    rignamess = fieldnames(rigs);
    rigsel = rignamess{1};
    
    [expts, exptns] = listexpts(rigs.(rigsel));
    exptsel = expts{1};
end

%% UI
hfig = figure('position', [350 250 250 680], 'MenuBar', 'none', 'ToolBar', 'none');
topleft = [20 650 0 0];
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
% Ch1 in
uicontrol(hfig, 'Style', 'text', 'String', 'Ch1 Pulse', 'Position', topleft + [0 2*majory 50 20]);
hi1 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ch1_pulse_ind,...
    'Position', topleft + [0 2*majory+minory 50 20]);

% Opto in
uicontrol(hfig, 'Style', 'text', 'String', 'Opto Pulse', 'Position', topleft + [minorx 2*majory 60 20]);
hio = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).opto_channel,...
    'Position', topleft + [minorx 2*majory+minory 50 20]);

% Ch1 thresh
uicontrol(hfig, 'Style', 'text', 'String', 'Ch1 Thresh', 'Position', topleft + [0 3*majory 60 20]);
ht1 = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).ch1_pulse_thresh,...
    'Position', topleft + [0 3*majory+minory 50 20]);

% Min opto pulse width
uicontrol(hfig, 'Style', 'text', 'String', 'Opto MinPW', 'Position', topleft + [minorx 3*majory 65 20]);
hmpw = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).minpulsewidth,...
    'Position', topleft + [minorx 3*majory+minory 50 20]);

% Other channels
% Cam
uicontrol(hfig, 'Style', 'text', 'String', 'Cam Pulse', 'Position', topleft + [minorx*2 2*majory 55 20]);
hcam = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).camch,...
    'Position', topleft + [minorx*2 2*majory+minory 50 20]);

% Lick
uicontrol(hfig, 'Style', 'text', 'String', 'Licks', 'Position', topleft + [minorx*2 3*majory 30 20]);
hlick = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).lickch,...
    'Position', topleft + [minorx*2 3*majory+minory 50 20]);

% Window
% Pre window
uicontrol(hfig, 'Style', 'text', 'String', 'Pre Win', 'Position', topleft + [0 4*majory 50 20]);
hprew = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.prew,...
    'Position', topleft + [0 4*majory+minory 50 20]);

% Post window
uicontrol(hfig, 'Style', 'text', 'String', 'Post Win', 'Position', topleft + [minorx 4*majory 50 20]);
hpostw = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.postw,...
    'Position', topleft + [minorx 4*majory+minory 50 20]);

% Min train length
uicontrol(hfig, 'Style', 'text', 'String', 'Min train length', 'Position', topleft + [minorx*2 4*majory 80 20]);
hmtl = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.trainlength_threshold,...
    'Position', topleft + [minorx*2 4*majory+minory 50 20]);

% Flatten and Sliding window DFF
uicontrol(hfig, 'Style', 'text', 'String', '3. Preprocess: ', 'Position', topleft + [0 5*majory 200 20]);

% Flatten stim
hflat = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Flatten', 'Position', topleft + ...
    [0 5*majory+minory 90 20], 'Value', TrigCfg.flatten_data);

% DFF
hdff = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Slide-DFF:', 'Position', topleft + ...
    [minorx 5*majory+minory 90 20], 'Value', TrigCfg.dff_data, 'Callback', @dffswitch);
hdffw = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.dff_win, 'Position', ...
    topleft + [2*minorx 5*majory+minory 30 20]);
uicontrol(hfig, 'Style', 'text', 'String', 's', 'Position', topleft + ...
    [2*minorx+30 5*majory+minory-3 10 20]);
hdffp = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.dff_prc, 'Position', ...
    topleft + [2*minorx+50 5*majory+minory 20 20]);
uicontrol(hfig, 'Style', 'text', 'String', '%', 'Position', topleft + ...
    [2*minorx+70 5*majory+minory-3 10 20]);
dffswitch(hdff, []);

% Rare items
uicontrol(hfig, 'Style', 'text', 'String', '4. Rare changes: ', 'Position', topleft + [0 6*majory 200 20]);

% Suffix
uicontrol(hfig, 'Style', 'text', 'String', 'File suffix:', 'Position', topleft + [0 6*majory+minory-3 60 20]);
hsuffix = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.suffix,...
    'Position', topleft + [minorx 6*majory+minory 120 20]);

% Interpolate
chs = num2cell(1:8)';
hint = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Interpolate artifact', 'Position', topleft + ...
    [0 7*majory 120 20], 'Value', TrigCfg.Remove_artifacts, 'Callback', @intswitch);
hintch = uicontrol(hfig, 'Style', 'listbox', 'String', chs, 'max', 8, 'min', 0, 'Position', topleft + ...
    [20, 8*majory+minory*4, 60, 130], 'Value', TrigCfg.artifact_ch);
intswitch(hint);

% GLM
hglm = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'GLM artifact', 'Position', topleft + ...
    [minorx*2-20 7*majory 100 20], 'Value', TrigCfg.GLM_artifacts, 'Callback', @glmswitch);
hglmch = uicontrol(hfig, 'Style', 'listbox', 'String', chs, 'max', 8, 'min', 0, 'Position', topleft + ...
    [minorx*2, 8*majory+minory*4, 60, 130], 'Value', TrigCfg.GLM_ch);
glmswitch(hglm);

% Buttons
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Load', 'Position', ...
    topleft + [0 10*majory+2*minory 70 30], 'Callback', @loadsetting);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Done', 'Position', ...
    topleft + [75 10*majory+2*minory 70 30], 'Callback', @done);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', ...
    topleft + [150 10*majory+2*minory 70 30], 'Callback', @cancel);

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
        hi1.String = rigs.(rigsel).(exptsel).ch1_pulse_ind;
        hio.String = rigs.(rigsel).(exptsel).opto_channel;
        ht1.String = rigs.(rigsel).(exptsel).ch1_pulse_thresh;
        hmpw.String = rigs.(rigsel).(exptsel).minpulsewidth;
        hcam.String = rigs.(rigsel).(exptsel).camch;
        hlick.String = rigs.(rigsel).(exptsel).lickch;
    end

% Dff switch
    function dffswitch(src,~)
        if src.Value
            hdffw.Enable = 'on';
            hdffp.Enable = 'on';
        else
            hdffw.Enable = 'off';
            hdffp.Enable = 'off';
        end
    end

% Interpolate switch
    function intswitch(src,~)
        if src.Value
            hintch.Enable = 'on';
        else
            hintch.Enable = 'off';
        end
    end

% GLM switch
    function glmswitch(src,~)
        if src.Value
            hglmch.Enable = 'on';
        else
            hglmch.Enable = 'off';
        end
    end

% Cancel
    function cancel(~,~)
        close(hfig);
    end

% Done
    function done(~,~)
        TrigCfg.rig = rigsel;
        TrigCfg.mode = exptsel;
        
        % Expt specific info
        TrigCfg.ch1_pulse_ind = rigs.(rigsel).(exptsel).ch1_pulse_ind;
        TrigCfg.opto_channel = rigs.(rigsel).(exptsel).opto_channel;
        TrigCfg.ch1_pulse_thresh = rigs.(rigsel).(exptsel).ch1_pulse_thresh;
        TrigCfg.minpulsewidth = rigs.(rigsel).(exptsel).minpulsewidth;
        TrigCfg.optomode = rigs.(rigsel).(exptsel).optomode;
        TrigCfg.camch = rigs.(rigsel).(exptsel).camch;
        TrigCfg.lickch = rigs.(rigsel).(exptsel).lickch;
        
        % Window info
        TrigCfg.prew = str2double(hprew.String);
        TrigCfg.postw = str2double(hpostw.String);
        TrigCfg.trainlength_threshold = str2double(hmtl.String);
        
        % Preprocessing
        TrigCfg.flatten_data = hflat.Value;

        % Dff data
        TrigCfg.dff_data = hdff.Value;
        TrigCfg.dff_win = str2double(hdffw.String); % In seconds
        TrigCfg.dff_prc = str2double(hdffp.String); % Percentile (10 excitation, 90 inhibition)
                
        % Suffix
        TrigCfg.suffix = hsuffix.String;
        
        % Interpolate artifacts
        TrigCfg.Remove_artifacts = hint.Value;
        TrigCfg.artifact_ch = hintch.Value;
                
        % GLM regress out artifacts
        TrigCfg.GLM_artifacts = hglm.Value;
        TrigCfg.GLM_ch = hglmch.Value;
                
        assignin('base', 'TrigCfg', TrigCfg)
        close(hfig);
    end

% Load setting
    function loadsetting(~,~)
        [filename, filepath] = uigetfile(fullfile(defaultpath , '*_preprocessed_trig.mat'));
        TrigCfg = load(fullfile(filepath, filename), 'TrigCfg');
        TrigCfg = TrigCfg.TrigCfg;
        rigsel = TrigCfg.rig;
        exptsel = TrigCfg.mode;
                
        hrigsel.Value = find(strcmp(rignamess, rigsel));
        [expts, exptns] = listexpts(rigs.(rigsel));
        hexptsel.String = exptns;
        hexptsel.Value = find(strcmp(expts, exptsel));
        updateboxes();
        
        % Window
        hprew.String = num2str(TrigCfg.prew);
        hpostw.String = num2str(TrigCfg.postw);
        hmtl.String = num2str(TrigCfg.trainlength_threshold);
        
        % Preprocessing
        hflat.Value = TrigCfg.flatten_data;

        % Dff data
        hdff.Value = TrigCfg.dff_data;
        hdffw.String = num2str(TrigCfg.dff_win); % In seconds
        hdffp.String = num2str(TrigCfg.dff_prc); % Percentile (10 excitation, 90 inhibition)
        dffswitch(hdff, []);
        
        % Suffix
        hsuffix.String = TrigCfg.suffix;
        
        % Interpolate artifacts
        hint.Value = TrigCfg.Remove_artifacts;
        hintch.Value = TrigCfg.artifact_ch;
        intswitch(hint);
         
        % GLM regress out artifacts
        hglm.Value = TrigCfg.GLM_artifacts;
        hglmch.Value = TrigCfg.GLM_ch;
        glmswitch(hglm);
    end


end

