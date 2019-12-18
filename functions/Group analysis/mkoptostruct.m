function [datastruct, n_series] = mkoptostruct(inputloadingcell, varargin)
% mkdatastruct makes a triggered opto structure based on the input data addresses.
% [datastruct, n_series] = mkoptostruct(inputloadingcell, varargin)

% Parse input
p  = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Default photometry path

% Data type
addOptional(p, 'useunfiltered', false); % Use unfiltered data (and retrigger)
addOptional(p, 'refilter', []); % Pass a filter to refilter data (only usable on unfiltered data)

% zscore
% The order of priorities is:
% No sigma (if true) > External sigma (if provided as a scalar) > internal sigma (needs to be
% found in the trig file) > freshly calculated trial-by-trial sigma
addOptional(p, 'nozscore', false); % No zscore of data
addOptional(p, 'zscore_firstpt', 50); % First point for zscore
addOptional(p, 'externalsigma', []); % Feed a sigma for zscoring
addOptional(p, 'useinternalsigma', false); % Use internal sigma (which is calculated through tcpZ)
addOptional(p, 'badtrials', []); % Bad trials to remove (X by 2 matrix of [Session# Sweep#])

% Baseline and slope
addOptional(p, 'zero_baseline', false); % Add a Y-offset to zero the pre-stim baselines
addOptional(p, 'zero_baseline_per_session', true); % Zero baseline once per session (Using median
                                                   % from the first or later sweep)
addOptional(p, 'trialtozero', 1); % If only zeroing baseline once per sessoin, which sweep to use?
addOptional(p, 'linearleveling', false); % Use pre-stim data to linearly fix slope.

% Extra triggers
addOptional(p, 'pretrigwindow', []);    % Add data that are triggered before the onset of the stimulations
                                        % (input as [-Seconds_before_stim_1 -Seconds_before_stim_2])
                                        % The window is only applied to the start of each trigger
addOptional(p, 'posttrigwindow', []);   % Add data that are triggered after the last stimulation
                                        % (intput as [Seconds_after_stim_1 Seconds_after_stim_2])
                                        % The window is only applied to the start of each trigger

% Sanity checking 
addOptional(p, 'checkoptopulses', false); % Only used for sanity checking that 
                                          % the opto pulses are triggered correctly

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
datastruct = struct('photometry_trig', 0, 'photometry_trigavg', 0, 'mouse', '',... 
    'mouseid',[],'order', 0, 'rorder', 0, 'Fs', 0, 'nstims', 0, 'window_info', [0 0 0]);
datastruct = repmat(datastruct, [size(loadingcell,1), 1]);

% Load data
for i = 1 : n_series
    % Fill mouse name
    datastruct(i).mouse = inputloadingcell{i,1};
    
    % Load photometry things
    loaded = load(fullfile(loadingcell{i,1}, loadingcell{i,6}));
    
    % Pre-loading data (unfiltered) and trigger it
    % Skip this if we are just checking opto
    if p.useunfiltered && ~p.checkoptopulses
        
        if isempty(p.refilter)
            % Without refiltering
            data_tmp = loaded.data2use_unfilt;
        else
            % Refiltering (also used for pre/post triggering below)
            data_tmp = filter(p.refilter, loaded.data2use_unfilt);
        end
        
        % Initialize a triggered matrix
        trigmat = zeros(loaded.l, size(loaded.inds,1));
        for j = 1 : size(loaded.inds, 1)
            trigmat(:,j) = data_tmp(loaded.inds(j,1) : loaded.inds(j,2));
        end
        
        % Put it in the loaded structure
        loaded.trigmat = trigmat;
    end
    
    % Load data 
    % (Skip the whole thing if we are just checking opto)
    if p.nozscore && ~p.checkoptopulses
        % Load triggered data
        datastruct(i).photometry_trig = loaded.trigmat;
    elseif ~p.checkoptopulses
        % Mean and std
        mu = nanmean(loaded.data2use(p.zscore_firstpt:end));
        
        if ~isempty(p.externalsigma)
            % Use the external sigma, which is a provided scalar value
            gamma = p.externalsigma; 
        elseif p.useinternalsigma
            % Use the internal sigma, which is stored in the .mat file by
            % tcpZ
            gamma = loaded.Z(1);
        else
            gamma = nanstd(loaded.data2use(p.zscore_firstpt:end));
        end
        
        % Apply zscore
        datastruct(i).photometry_trig = (loaded.trigmat - mu) / gamma;
    end
    
    % Checking opto
    if p.checkoptopulses
        % Initialize a triggered matrix
        datastruct(i).photometry_trig = zeros(loaded.l, size(loaded.inds,1));
        for j = 1 : size(loaded.inds,1)
            datastruct(i).photometry_trig(:,j) = loaded.opto(loaded.inds(j,1) : loaded.inds(j,2));
        end
    end
    
    % Remove bad trials
    if ~isempty(p.badtrials)
        % Current bad trials
        currentbt = p.badtrials(p.badtrials(:,1) == i, 2);
        
        % Remove
        datastruct(i).photometry_trig(:,currentbt) = [];
        
        % Number of stims
        datastruct(i).nstims = loaded.n_optostims - length(currentbt);
    else
        % Number of stims
        datastruct(i).nstims = loaded.n_optostims;
    end
    
    % Zero baseline
    if p.zero_baseline % Per sweep
        % Baseline vector
        baselinevec = nanmean(datastruct(i).photometry_trig(1 : loaded.prew_f, :), 1);
        
        % Triggered photometry data
        datastruct(i).photometry_trig = datastruct(i).photometry_trig -...
            ones(loaded.l, 1) * baselinevec;
    elseif p.zero_baseline_per_session % Once per session
        % Baseline value
        baselineval = nanmedian(datastruct(i).photometry_trig(1 : loaded.prew_f, p.trialtozero));
        
        % Triggered photometry data
        datastruct(i).photometry_trig = datastruct(i).photometry_trig -...
            baselineval;
    end
    
    % Fix slope
    if p.linearleveling
        % Pre-stim data
        y = nanmean(datastruct(i).photometry_trig(1:loaded.prew_f, :), 2);
        x = (-loaded.prew_f + 1 : 0)';
        
        % fit
        fitinfo = fit(x, y, 'poly1');
        
        % Correct data
        fitdata = fitinfo(-loaded.prew_f:loaded.postw_f) * ones(1, size(datastruct(i).photometry_trig,2));
        datastruct(i).photometry_trig = datastruct(i).photometry_trig - fitdata;
        
        % Get slope
        datastruct(i).sloperemoved = fitinfo.p1;
    end
    
    % Pre-trigger window
    % (Skip this if we are checking opto)
    if ~isempty(p.pretrigwindow) && ~p.checkoptopulses        
        
        % Get periodicity of indices
        inds_per = round(mean(diff(loaded.inds(:,1),1)));
        
        % Pre-trigger
        inds_pretrig = (p.pretrigwindow(1) * loaded.freq + loaded.inds(1,1) :...
            inds_per : p.pretrigwindow(2) * loaded.freq + loaded.inds(1,1))';
        inds_pretrig(:,2) = inds_pretrig(:,1) + loaded.l - 1;
        
        % Make sure nothing is out of bounds
        inds_pretrig = inds_pretrig(inds_pretrig(:,1) > 0, :);
        
        % Pre-triggered data
        pretrigmat = zeros(loaded.l, size(inds_pretrig,1));
        for j = 1 : size(inds_pretrig,1)
            if p.useunfiltered
                pretrigmat(:,j) = data_tmp(inds_pretrig(j,1) : inds_pretrig(j,2));
            else
                pretrigmat(:,j) = loaded.data2use(inds_pretrig(j,1) : inds_pretrig(j,2));
            end
        end
        
        % zscore
        if ~p.nozscore
            pretrigmat = (pretrigmat - mu) / gamma;
        end
        
        % Zero baseline
        if p.zero_baseline % Zero baseline per sweep
            % Baseline vector
            baselinevec_pretrig = nanmean(pretrigmat(1 : loaded.prew_f, :), 1);
            
            % Triggered photometry data
            pretrigmat = pretrigmat -...
                ones(loaded.l, 1) * baselinevec_pretrig;
        elseif p.zero_baseline_per_session % Once per session
            pretrigmat = pretrigmat - baselineval;
        end
        
        % Put the pre-triggered data in the structure
        datastruct(i).photometry_pretrig = pretrigmat;
    end
    
    % Post-trigger window
    % (Skip this if we are checking opto)
    if ~isempty(p.posttrigwindow) && ~p.checkoptopulses        
        
        % Get periodicity of indices
        inds_per = round(mean(diff(loaded.inds(:,1),1)));
        
        % Post-trigger
        inds_posttrig = (p.posttrigwindow(1) * loaded.freq + loaded.inds(end,2) :...
            inds_per : p.posttrigwindow(2) * loaded.freq + loaded.inds(end,2))';
        inds_posttrig(:,2) = inds_posttrig(:,1) + loaded.l - 1;
        
        % Make sure nothing is out of bounds
        maxind = length(loaded.data2use);
        inds_posttrig = inds_posttrig(inds_posttrig(:,2) <= maxind, :);
        
        % Post-triggered data
        posttrigmat = zeros(loaded.l, size(inds_posttrig,1));
        for j = 1 : size(inds_posttrig,1)
            if p.useunfiltered
                posttrigmat(:,j) = data_tmp(inds_posttrig(j,1) : inds_posttrig(j,2));
            else
                posttrigmat(:,j) = loaded.data2use(inds_posttrig(j,1) : inds_posttrig(j,2));
            end
        end
        
        % zscore
        if ~p.nozscore
            posttrigmat = (posttrigmat - mu) / gamma;
        end
        
        % Zero baseline
        if p.zero_baseline % Zero baseline per sweep
            % Baseline vector
            baselinevec_posttrig = nanmean(posttrigmat(1 : loaded.prew_f, :), 1);
            
            % Triggered photometry data
            posttrigmat = posttrigmat -...
                ones(loaded.l, 1) * baselinevec_posttrig;
        elseif p.zero_baseline_per_session % Once per session
            posttrigmat = posttrigmat - baselineval;
        end
        
        % Put the post-triggered data in the structure
        datastruct(i).photometry_posttrig = posttrigmat;
    end
    
    % Calculate average
    datastruct(i).photometry_trigavg = mean(datastruct(i).photometry_trig, 2);
    
    % Order
    datastruct(i).order = 1 : size(datastruct(i).photometry_trig, 2);
    
    % Reverse order
    datastruct(i).rorder = size(datastruct(i).photometry_trig, 2) : -1 : 1;
    
    % Frequency
    datastruct(i).Fs = loaded.freq;
    
    % Load window info
    datastruct(i).window_info = [loaded.prew_f, loaded.postw_f, loaded.l];
    
end

%% Additional stuff
% A cell of the mice
mice_cell = unique({datastruct(:).mouse});

for i = 1 : n_series
    % Mouse id
    mouseid = find(strcmp(mice_cell, datastruct(i).mouse));
    
    % Fill mouse id
    datastruct(i).mouseid = ones(1, datastruct(i).nstims) * mouseid;
end

end