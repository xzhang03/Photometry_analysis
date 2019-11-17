function [datatraces, n_series] = mkoptotraces(inputloadingcell, varargin)
% mkoptotraces makes overall traces of repeated opto stims
% [datatraces, n_series] = mkoptotraces(inputloadingcell, varargin)

% Parse input
p  = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Default photometry path

% Sampling paramters
addOptional(p, 'Fs', 50); % Downsample if specified
addOptional(p, 'usedff', false); % Use sliding window df/f

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
addOptional(p, 'prestimfitinfo', false); % Calculate a pre-stim fit
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
    data2use = loaded.data2use;
    
    % df/f if called for
    if p.usedff
        data2use = tcpPercentiledff(data2use, loaded.freq);
    end
    
    % Get data and zscore
    if ~p.nozscore
        data2use = tcpZscore(data2use, 1 : p.zscore_firstpt, p.externalsigma);
    end
    
    % Get opto ons
    opto_ons = loaded.opto_ons;
    
    % Load opto
    if isfield('loaded', 'opto')
        % Load opto the straight-foward way
        opto = loaded.opto(:, 2);
    else
        % Load opto the other way (sigh)
        opto = load(fullfile(loadingcell{i,1}, loadingcell{i,4}), 'opto_pulse_table');
        opto = opto.opto_pulse_table(:, 2);
    end
    
    % Downsample if needed
    if p.Fs < loaded.freq
        % Downsample
        data2use = tcpBin(data2use, loaded.freq, p.Fs, 'mean', 1, true);
        opto = tcpBin(opto, loaded.freq, p.Fs, 'max', 1, true);
        Fs = p.Fs;
        
        % Downsample factor
        ds_factor = loaded.freq / Fs;
        
        % Downsample factor is not integer
        if round(ds_factor) ~= ds_factor
            warning('Downsample factor is not integer.')
        end
        
        % Down sample opto ons
        opto_ons = round(opto_ons / ds_factor);
    else
        Fs = loaded.freq;
    end
    
    % Clean up opto ons
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
    
    % Get a DC offset
    if p.zero_baseline
        DCoffset = nanmean(datasplitter(data2use, [p.OnWindow(1), 0] * Fs + opto_ons(1), 1));
        datatraces(i).DC_offset = DCoffset;
    else
        DCoffset = 0;
    end
    
    % Get prestim slope
    if p.prestimfitinfo
        % Get data
        y = datasplitter(data2use, [p.OnWindow(1), 0] * Fs + opto_ons(1), 1);
        y = y(p.prestimslope_firstpt : end);
        x = (-length(y) + 1 : 0)';
        
        % fit
        fitinfo = fit(x, y, 'poly1');
        
        % Get slope
        datatraces(i).prestimfit = [fitinfo.p1, fitinfo.p2];
    end
    
    % Fill Fs
    datatraces(i).Fs = Fs;
    
    % Fill first and last opto pulses
    datatraces(i).optofirstlast = [opto_ons(1), opto_ons(end)];
    
    % Fill stim-onset photometry data
    datatraces(i).photometry_stimON = ...
        datasplitter(data2use, p.OnWindow * Fs + opto_ons(1), 1) - DCoffset;
    
    % Fill stim-onset opto pulse data
    datatraces(i).opto_stimON = ...
        datasplitter(opto, p.OnWindow * Fs + opto_ons(1), 1);
    
    % Fill onset window info
    datatraces(i).window_info_ON = p.OnWindow * Fs;
    
    % Fill stim-offset photometry data
    datatraces(i).photometry_stimOFF = ...
        datasplitter(data2use, p.OffWindow * Fs + opto_ons(end), 1) - DCoffset;
    
    % Fill stim-offset opto pulse data
    datatraces(i).opto_stimOFF = ...
        datasplitter(opto, p.OffWindow * Fs + opto_ons(end), 1);
    
    % Fill onset window info
    datatraces(i).window_info_OFF = p.OffWindow * Fs;
end
end
