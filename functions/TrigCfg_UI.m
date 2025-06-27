function hfig = TrigCfg_UI(defaultpath)
% ppCfg_UI uses an ui to generate config for photometry preprocessing

%% Initial setting
if nargin < 1
    defaultpath = '';
end

% Apollo scoptophoto (GCaMP + biPAC)
rigs.Apollo.scoptophoto.name = 'Apollo GCaMP + biPAC';
rigs.Apollo.scoptophoto.mode = '1. Green sensor + Blue stim';
rigs.Apollo.scoptophoto.minpulsewidth = [];
rigs.Apollo.scoptophoto.optomode = true;
rigs.Apollo.scoptophoto.trigtone = false;

% Apollo licks (GCaMP + biPAC)
rigs.Apollo.licks.name = 'Apollo GCaMP (licks)';
rigs.Apollo.licks.mode = '2. Green sensor + licks (+ red)';
rigs.Apollo.licks.minpulsewidth = [];
rigs.Apollo.licks.optomode = true;
rigs.Apollo.licks.trigtone = false;

% Apollo optophoto (Green Sensor + Red Stim)
rigs.Apollo.foodphoto.name = 'Apollo GCaMP + Cued feeding';
rigs.Apollo.foodphoto.mode = '3. Green sensor + Cued';
rigs.Apollo.foodphoto.minpulsewidth = 5;
rigs.Apollo.foodphoto.optomode = true;
rigs.Apollo.foodphoto.trigtone = true;

% Artemis optophoto (Green Sensor + Red Stim)
rigs.Artemis.optophoto.name = 'Artemis GCaMP + Chrimson';
rigs.Artemis.optophoto.mode = '1. Green sensor + Red stim';
rigs.Artemis.optophoto.minpulsewidth = 5;
rigs.Artemis.optophoto.optomode = true;
rigs.Artemis.optophoto.trigtone = false;

% Artemis optophoto (Green Sensor + Red Stim)
rigs.Artemis.foodphoto.name = 'Artemis GCaMP + Cued feeding';
rigs.Artemis.foodphoto.mode = '2. Green sensor + Cued';
rigs.Artemis.foodphoto.minpulsewidth = 5;
rigs.Artemis.foodphoto.optomode = true;
rigs.Artemis.foodphoto.trigtone = true;

% Cleopatra optophoto (Green Sensor + Red Stim)
rigs.cleopatra.optophoto.name = 'Cleopatra GCaMP + Chrimson';
rigs.cleopatra.optophoto.mode = '1. Green sensor + Red stim';
rigs.cleopatra.optophoto.minpulsewidth = 5;
rigs.cleopatra.optophoto.optomode = true;
rigs.cleopatra.optophoto.trigtone = false;

% Minerva optophoto
rigs.minerva.optophoto.name = 'Minerva placeholder';
rigs.minerva.optophoto.mode = '1. placeholder';
rigs.minerva.optophoto.minpulsewidth = 99;
rigs.minerva.optophoto.optomode = true;
rigs.minerva.optophoto.trigtone = false;

% RBG optophoto (RCaMP + ChR2)
rigs.rbg.optophoto.name = 'RBG RCaMP + ChR2';
rigs.rbg.optophoto.mode = '1. Red sensor + Blue stim';
rigs.rbg.optophoto.minpulsewidth = [];
rigs.rbg.optophoto.optomode = true;
rigs.rbg.optophoto.trigtone = false;

% RBG scoptophoto (GCaMP + biPAC)
rigs.rbg.scoptophoto.name = 'RBG GCaMP + biPAC';
rigs.rbg.scoptophoto.mode = '2. Green sensor + Blue stim';
rigs.rbg.scoptophoto.minpulsewidth = [];
rigs.rbg.scoptophoto.optomode = true;
rigs.rbg.scoptophoto.trigtone = false;

% RBG scoptophoto (GCaMP + Audio)
rigs.rbg.audiophoto.name = 'RBG GCaMP + Audio Trigger';
rigs.rbg.audiophoto.mode = '3. Green sensor + Audio Trig';
rigs.rbg.audiophoto.minpulsewidth = [];
rigs.rbg.audiophoto.optomode = true;
rigs.rbg.audiophoto.trigtone = true;

% RBG scoptophoto (GCaMP + Audio)
rigs.rbg.foodphoto.name = 'RBG GCaMP + Food Trigger';
rigs.rbg.foodphoto.mode = '4. Green sensor + Food Trig';
rigs.rbg.foodphoto.minpulsewidth = [];
rigs.rbg.foodphoto.optomode = true;
rigs.rbg.foodphoto.trigtone = true;

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
    TrigCfg.usech2 = false;
    TrigCfg.flatten_data = false;

    % Dff data
    TrigCfg.dff_data = false;
    TrigCfg.dff_win = 60; % In seconds
    TrigCfg.dff_prc = 10; % Percentile (10 excitation, 90 inhibition)

    % Window info (seconds before and after pulse onsets)
    if ~isfield(TrigCfg, 'prew')
        TrigCfg.prew = 10; % 8
    end
    if ~isfield(TrigCfg, 'postw')
        TrigCfg.postw = 50; % 28
    end
    
    % Use offset
    TrigCfg.useoffset = false;

    % Interpolate out artifacts (problem with small NIDAQs)
    TrigCfg.Remove_artifacts = false;
    TrigCfg.artifact_ch = 1;

    % GLM regress out artifacts
    TrigCfg.GLM_artifacts = false;
    TrigCfg.GLM_ch = 1;

    % Pulses within this number of seconds will be merged together as the
    % same train. This creates a natural ITI
    TrigCfg.merge = 5;

    % Trains shorther than this length will be removed
    TrigCfg.minlength = 0;

    % Trains closers to the previous train than this length will be removed
    TrigCfg.minITI = 0;

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
hfig = figure('position', [350 100 250 710], 'MenuBar', 'none', 'ToolBar', 'none');
topleft = [20 650 0 0];
minory = -20;
majory = -60;
minorx = 70;

% Keep track of current y
currenty = 0;

% Rig
uicontrol(hfig, 'Style', 'text', 'String', '1. Select a rig: ', 'Position', topleft + [0 currenty 200 20]);
hrigsel = uicontrol(hfig, 'Style', 'popup', 'String', rignamess, 'Position', topleft + [0, currenty + minory, 200, 20], ...
    'Callback', @getexpts, 'Value', find(strcmp(rignamess, rigsel)));

% Expts
currenty = currenty + majory;
uicontrol(hfig, 'Style', 'text', 'String', '2. Select an experiment: ', 'Position', topleft + [0 currenty 200 20]);
hexptsel = uicontrol(hfig, 'Style', 'popup', 'String', exptns, 'Position', topleft + [0, currenty + minory, 200, 20], ...
    'Callback', @getboxes, 'Value', find(strcmp(expts, exptsel)));

% Boxes
currenty = currenty + majory;

% Other channels
% Pre window
uicontrol(hfig, 'Style', 'text', 'String', 'Pre Win', 'Position', topleft + [0 currenty 50 20]);
hprew = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.prew,...
    'Position', topleft + [0 currenty+minory 50 20]);

% Post window
uicontrol(hfig, 'Style', 'text', 'String', 'Post Win', 'Position', topleft + [minorx currenty 50 20]);
hpostw = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.postw,...
    'Position', topleft + [minorx currenty+minory 50 20]);

% Min opto pulse width
uicontrol(hfig, 'Style', 'text', 'String', 'Opto MinPW', 'Position', topleft + [minorx*2 currenty 65 20]);
hmpw = uicontrol(hfig, 'Style', 'edit', 'String', rigs.(rigsel).(exptsel).minpulsewidth,...
    'Position', topleft + [minorx*2 currenty+minory 50 20], 'callback', @updaterigsfromboxes);

% Other channels
% Window
currenty = currenty + majory;

% Merge length
uicontrol(hfig, 'Style', 'text', 'String', 'Merge length', 'Position', topleft + [0 currenty 65 20]);
hmel = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.merge,...
    'Position', topleft + [0 currenty+minory 50 20]);

% Min length
uicontrol(hfig, 'Style', 'text', 'String', 'Min length', 'Position', topleft + [minorx currenty 55 20]);
hminl = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.minlength,...
    'Position', topleft + [minorx currenty+minory 50 20]);

% Min length
uicontrol(hfig, 'Style', 'text', 'String', 'Min ITI', 'Position', topleft + [minorx*2 currenty 50 20]);
hminiti = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.minITI,...
    'Position', topleft + [minorx*2 currenty+minory 50 20]);

% Channel 2
currenty = currenty + majory;
currenty = currenty + minory;
hc2 = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Use Ch2', 'Position', topleft + ...
    [0 currenty 90 20], 'Value', TrigCfg.usech2, 'callback', @updaterigsfromboxes);

% Tone
currenty = currenty + minory;
hct = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Trigger Tone', 'Position', topleft + ...
    [0 currenty 90 20], 'Value', rigs.(rigsel).(exptsel).trigtone, 'callback', @updaterigsfromboxes);

% Offset
hos = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Use Offset', 'Position', topleft + ...
    [1.5*minorx currenty 90 20], 'Value', TrigCfg.useoffset, 'callback', @updaterigsfromboxes);

% Flatten and Sliding window DFF
currenty = currenty + minory + minory;
uicontrol(hfig, 'Style', 'text', 'String', '3. Preprocess: ', 'Position', topleft + [0 currenty 200 20]);

% Flatten stim
hflat = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Flatten', 'Position', topleft + ...
    [0 currenty+minory 90 20], 'Value', TrigCfg.flatten_data);

% DFF
hdff = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Slide-DFF:', 'Position', topleft + ...
    [minorx currenty+minory 90 20], 'Value', TrigCfg.dff_data, 'Callback', @dffswitch);
hdffw = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.dff_win, 'Position', ...
    topleft + [2*minorx currenty+minory 30 20]);
uicontrol(hfig, 'Style', 'text', 'String', 's', 'Position', topleft + ...
    [2*minorx+30 currenty+minory-3 10 20]);
hdffp = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.dff_prc, 'Position', ...
    topleft + [2*minorx+50 currenty+minory 20 20]);
uicontrol(hfig, 'Style', 'text', 'String', '%', 'Position', topleft + ...
    [2*minorx+70 currenty+minory-3 10 20]);
dffswitch(hdff, []);

% Rare items
currenty = currenty + majory;
uicontrol(hfig, 'Style', 'text', 'String', '4. Rare changes: ', 'Position', topleft + [0 currenty 200 20]);

% Suffix
uicontrol(hfig, 'Style', 'text', 'String', 'File suffix:', 'Position', topleft + [0 currenty+minory-3 60 20]);
hsuffix = uicontrol(hfig, 'Style', 'edit', 'String', TrigCfg.suffix,...
    'Position', topleft + [minorx currenty+minory 120 20]);

% Interpolate
currenty = currenty + majory;
chs = {'Ens', 'Licks', 'Opto'};
hint = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'Interpolate artifact', 'Position', topleft + ...
    [0 currenty 120 20], 'Value', TrigCfg.Remove_artifacts, 'Callback', @intswitch);
hintch = uicontrol(hfig, 'Style', 'listbox', 'String', chs, 'max', 8, 'min', 0, 'Position', topleft + ...
    [20, currenty+majory+minory*4, 60, 130], 'Value', TrigCfg.artifact_ch);
intswitch(hint);

% GLM
hglm = uicontrol(hfig, 'Style', 'radiobutton', 'String', 'GLM artifact', 'Position', topleft + ...
    [minorx*2-20 currenty 100 20], 'Value', TrigCfg.GLM_artifacts, 'Callback', @glmswitch);
hglmch = uicontrol(hfig, 'Style', 'listbox', 'String', chs, 'max', 8, 'min', 0, 'Position', topleft + ...
    [minorx*2, currenty+majory+minory*4, 60, 130], 'Value', TrigCfg.GLM_ch);
glmswitch(hglm);

% Buttons
currenty = currenty + 2 * majory + minory;
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Load Setting', 'Position', ...
    topleft + [0 currenty+2*minory 70 30], 'Callback', @loadsetting);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Done', 'Position', ...
    topleft + [75 currenty+2*minory 70 30], 'Callback', @done);
uicontrol(hfig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', ...
    topleft + [150 currenty+2*minory 70 30], 'Callback', @cancel);

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
        hmpw.String = rigs.(rigsel).(exptsel).minpulsewidth;
        hct.Value = rigs.(rigsel).(exptsel).trigtone;
    end

% Update rigs from boxes
    function updaterigsfromboxes(~,~)
        rigs.(rigsel).(exptsel).minpulsewidth = str2double(hmpw.String);
        rigs.(rigsel).(exptsel).trigtone = hct.Value;
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
        TrigCfg.minpulsewidth = rigs.(rigsel).(exptsel).minpulsewidth;
        TrigCfg.optomode = rigs.(rigsel).(exptsel).optomode;
        TrigCfg.trigtone = rigs.(rigsel).(exptsel).trigtone;
        
        % Window info
        TrigCfg.prew = str2double(hprew.String);
        TrigCfg.postw = str2double(hpostw.String);
        TrigCfg.merge = str2double(hmel.String);
        TrigCfg.minlength = str2double(hminl.String);
        TrigCfg.minITI = str2double(hminiti.String);

        % Preprocessing
        TrigCfg.flatten_data = hflat.Value;
        TrigCfg.usech2 = hc2.Value;

        % Offset
        TrigCfg.useoffset = hos.Value;

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
        
        % Rigs
        TrigCfg.rigs = rigs;
        
        assignin('base', 'TrigCfg', TrigCfg)
        close(hfig);
    end

% Load setting
    function loadsetting(~,~)
        [filename, filepath] = uigetfile(fullfile(defaultpath , '*_preprocessed_trig*.mat'));
        TrigCfg = load(fullfile(filepath, filename), 'TrigCfg');
        if isfield(TrigCfg, 'rigs')
            rigs = TrigCfg.rigs;
        end
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
        hmel.String = num2str(TrigCfg.merge);
        hminl.String = num2str(TrigCfg.minlength);
        hminiti.String = num2str(TrigCfg.minITI);
        
        % Preprocessing
        hflat.Value = TrigCfg.flatten_data;
        hc2.Value = TrigCfg.usech2;

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

        % Offset
        hos.Value = TrigCfg.useoffset;

    end


end

