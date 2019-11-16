function [datatraces, n_series] = mkoptotraces(inputloadingcell, varargin)
% mkoptotraces makes overall traces of repeated opto stims
% [datatraces, n_series] = mkoptotraces(inputloadingcell, varargin)

% Parse input
p  = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Default photometry path

% Opto parameters
addOptional(p, 'clean_OptoOns', true); % Clean up opto ons to get better alignment

% Zscore parameters
addOptional(p, 'nozscore', false); % No zscore of data
addOptional(p, 'zscore_firstpt', 50); % First point for zscore
addOptional(p, 'zero_baseline', true); % Add a Y-offset to zero the pre-stim baselines
addOptional(p, 'externalsigma', []); % Feed a sigma for zscoring

% Window paramters
addOptional(p, 'OnWindow', [-300 600]); % Window in seconds for onset of stimulation [Before After]
addOptional(p, 'OffWindow', [-600 600]); % Window in seconds for offset of stimulation [Before After]

% Other info
addOptional(p, 'prestimslope', false); % Calculate a pre-stim slope
addOptional(p, 'prestimslope_firstpt', 250); % First point to use for pre-stim slope

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath);

% data samples
n_series = size(loadingcell, 1);

% Initialize
datatraces = struct('photometry_stimON', 0, 'opto_stimON', 0,....
    'photometry_stimOFF', 0, 'opto_stimOFF', 0, 'Fs', 0, 'optofirstlast', [0 0],...
    'window_info_ON', [0 0], 'window_info_OFF', [0 0], 'DC_offset', 0);
datatraces = repmat(datatraces, [size(loadingcell,1), 1]);

% Load data
for i = 1 : n_series
    % Load photometry things
    loaded = load(fullfile(loadingcell{i,1}, loadingcell{i,6}));
    
    % Get data and zscore
    if p.nozscore
        data2use = loaded.data2use;
    else
        data2use = tcpZscore(loaded.data2use, 1 : p.zscore_firstpt, p.externalsigma);
    end
    
    % Clean up opto ons
    opto_ons = loaded.opto_ons;
    if p.clean_OptoOns
        % Get opto ITI
        opto_ITI = diff(opto_ons);
        
        % Get typical ITI
        opto_ITI_typical = mode(opto_ITI);
        
        % First train
        if opto_ITI(1) < opto_ITI_typical
            % First train is incomplete
            opto_ons(1) = opto_ons(2) - opto_ITI_typical;
        end
        
    end
    
    % Load opto
    if isfield('loaded', 'opto')
        % Load opto the straight-foward way
        opto = loaded.opto;
    else
        % Load opto the other way (sigh)
        opto = load(fullfile(loadingcell{i,1}, loadingcell{i,4}), 'opto_pulse_table');
        opto = opto.opto_pulse_table;
    end
    
    % Get a DC offset
    if p.zero_baseline
        DCoffset = nanmean(datasplitter(data2use, [p.OnWindow(1), 0] * loaded.freq + opto_ons(1), 1));
        datatraces(i).DC_offset = DCoffset;
    else
        DCoffset = 0;
    end
    
    % Get prestim slope
    if p.prestimslope
        % Get data
        y = datasplitter(data2use, [p.OnWindow(1), 0] * loaded.freq + opto_ons(1), 1);
        y = y(p.prestimslope_firstpt : end);
        x = (1 : length(y))';
        
        % fit
        fitinfo = fit(x, y, 'poly1');
        
        % Get slope
        datatraces(i).prestimslope = fitinfo.p1;
    end
    
    % Fill Fs
    datatraces(i).Fs = loaded.freq;
    
    % Fill first and last opto pulses
    datatraces(i).optofirstlast = [opto_ons(1), opto_ons(end)];
    
    % Fill stim-onset photometry data
    datatraces(i).photometry_stimON = ...
        datasplitter(data2use, p.OnWindow * loaded.freq + opto_ons(1), 1) - DCoffset;
    
    % Fill stim-onset opto pulse data
    datatraces(i).opto_stimON = ...
        datasplitter(opto(:,2), p.OnWindow * loaded.freq + opto_ons(1), 1);
    
    % Fill onset window info
    datatraces(i).window_info_ON = p.OnWindow * loaded.freq;
    
    % Fill stim-offset photometry data
    datatraces(i).photometry_stimOFF = ...
        datasplitter(data2use, p.OffWindow * loaded.freq + opto_ons(end), 1) - DCoffset;
    
    % Fill stim-offset opto pulse data
    datatraces(i).opto_stimOFF = ...
        datasplitter(opto(:,2), p.OffWindow * loaded.freq + opto_ons(end), 1);
    
    % Fill onset window info
    datatraces(i).window_info_OFF = p.OffWindow * loaded.freq;
end
end
