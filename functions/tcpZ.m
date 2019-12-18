function tcpZ(inputloadingcell, varargin)
% tcpZ calculates standard deviation per animal across all experiments
% (means are subtracted on an experiment-by-experiment basis). Zs are
% calculated based on unflattened data (raw or filtered) but can be applied
% to any file type.

%% Parse input
p  = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Default photometry path

addOptional(p, 'inputdatatype', 'filtered'); % Can be 'filtered' or 'raw'

addOptional(p, 'outputfiletype', 'trig'); % Can be 'preprocessed', 'fixed', or 'trig'

addOptional(p, 'zscore_firstpt', 50); % First point to calculate Z score

addOptional(p, 'nchannels', 1); % Can be one or two channels

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Clean up input parameters
if p.nchannels > 2
    p.nchannels = 2;
end

%% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath);

%% Process each mouse
% A cell of unique mice
mice_cell = unique(inputloadingcell(:,1));
nmice = length(mice_cell);

% Start
fprintf('============= Checking %i mice =============\n', nmice);

% Loop through
for mouseind = 1 : nmice
    % Get current indices
    curr_inds = find(strcmp(inputloadingcell(:,1), mice_cell{mouseind}));
    n_curr_inds = length(curr_inds);
    
    % Initialize a cell to contain data
    datacell = cell(n_curr_inds, p.nchannels);
    
    for exptind = 1 : n_curr_inds
        % Grab the actual global ind
        ind = curr_inds(exptind);
        
        % Load
        switch p.inputdatatype
            case 'filtered'
                % Load photometry data
                loaded = ...
                    load(fullfile(loadingcell{ind,1}, loadingcell{ind,4}),...
                    'Ch1_filtered', 'Ch2_filtered');
                
                % Put data in cell (mean-subtracted)
                datacell{ind, 1} = loaded.Ch1_filtered(p.zscore_firstpt : end)...
                    - nanmean(loaded.Ch1_filtered(p.zscore_firstpt : end));
                
                if p.nchannels == 2
                    datacell{ind, 2} = loaded.Ch2_filtered(p.zscore_firstpt : end)...
                        - nanmean(loaded.Ch2_filtered(p.zscore_firstpt : end));
                end
                
            case 'raw'
                % Load photometry data
                loaded = ...
                    load(fullfile(loadingcell{ind,1}, loadingcell{ind,4}),...
                    'ch1_data_table', 'ch2_data_table');
                
                % Put data in cell (mean-subtracted)
                datacell{ind, 1} = ...
                    loaded.ch1_data_table(p.zscore_firstpt : end,2)...
                    - nanmean(loaded.ch1_data_table(p.zscore_firstpt : end,2));
                
                if p.nchannels > 1
                    datacell{ind, 2} = ...
                        loaded.ch2_data_table(p.zscore_firstpt : end,2)...
                        - nanmean(loaded.ch2_data_table(p.zscore_firstpt : end,2));
                end
        end
    end
    
    % Concatenate data
    datavec1 = cell2mat(datacell(:,1));
    
    % Get Z
    Z = nanstd(datavec1);
    fprintf('%s has a z-value of %3.3f in Channel 1\n', mice_cell{mouseind}, Z);
    
    % Second channel if needed
    if p.nchannels > 1
        % Concatenate data
        datavec2 = cell2mat(datacell(:,2));
        
        % Get Z
        Z(2) = nanstd(datavec2);
        
        % Second channel
        fprintf('%s has a z-value of %3.3f in Channel 2\n',...
            mice_cell{mouseind}, Z(2));
    end
    
    % Save Z
    for exptind = 1 : n_curr_inds
        % Grab the actual global ind
        ind = curr_inds(exptind);
        
        % File name
        switch p.outputfiletype
            case 'trig'
                savefn = fullfile(loadingcell{ind,1}, loadingcell{ind,6});
            case 'fixed'
                savefn = fullfile(loadingcell{ind,1}, loadingcell{ind,2});
            case 'preprocessed'
                savefn = fullfile(loadingcell{ind,1}, loadingcell{ind,4});
        end
        
        % Save
        save(savefn, 'Z', '-append');
    end
    
    % Broadcast
    fprintf('Z-value has been saved to the %s files of %s\n',...
            p.outputfiletype, mice_cell{mouseind});
end
end