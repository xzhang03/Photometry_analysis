function tcpFixTrigger(inputloadingcell, varargin)
% tcpFixTrigger fixes trig matrices by adding missing fields

% Parse input
p  = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Default photometry path

addOptional(p, 'flatten_unfiltered', false); % Use the same exponential fit to flatten the unfiltered traces

addOptional(p, 'add_opto', false); % Add opto pulses from the pre-processed data
addOptional(p, 'force_add_opto', false); % Force add/redo the opto field

addOptional(p, 'reduce_opto', false); % Turn opto pulses from m-by-3 to m-by-1 arrays

addOptional(p, 'checkfield', ''); % Add a field to check

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

%% Flatten unfiltered traces
% Start
fprintf('========== Checking %i experiments ==========\n', n_series);

for i = 1 : n_series
    % Trig file
    Trig_fn = fullfile(loadingcell{i,1}, loadingcell{i,6});
    
    % Load triggered data
    loaded_trig = load(Trig_fn);
    
    % Load preprocessed
    loaded_prep = load(fullfile(loadingcell{i,1}, loadingcell{i,4}), 'opto_pulse_table',...
        'Ch1_filtered', 'ch1_data_table');
    
    % Add opto
    if p.add_opto
        if ~isfield(loaded_trig,'opto') || p.force_add_opto
            % Get opto
            opto = loaded_prep.opto_pulse_table(:,2); %#ok<NASGU>
            
            % Add field
            loaded_trig.opto = opto;
            
            % Append and display
            save(Trig_fn, 'opto', '-append');
            fprintf('%s: added opto\n', loadingcell{i,6});
        end
    end
    
    % Reduce opto column numbers
    if p.reduce_opto
        if isfield(loaded_trig, 'opto')
            if size(loaded_trig.opto, 2) == 3
                % Reduce
                opto = loaded_trig.opto(:,2); %#ok<NASGU>
                
                % Append and display
                save(Trig_fn, 'opto', '-append');
                fprintf('%s: reduced opto\n', loadingcell{i,6});
            end
        end
    end
    
    % Flatten the unfiltered trace
    if p.flatten_unfiltered
        if ~isfield(loaded_trig,'data2use_unfilt')
            
            % Get exp fit
            exp_fit = loaded_prep.Ch1_filtered - loaded_trig.data2use;
            
            % Flatten
            data2use_unfilt = loaded_prep.ch1_data_table(:,2) - exp_fit; %#ok<NASGU>
            
            % Save
            save(Trig_fn, 'data2use_unfilt', 'exp_fit', '-append');
            
            % Display
            fprintf('%s: flattened unfiltered traces\n', loadingcell{i,6});
        end
    end
    
    % Check for fields
    if ~isempty(p.checkfield)
        if ~isfield(loaded_trig, p.checkfield)
            % Display
            fprintf('%s: missing field: %s\n', loadingcell{i,6}, p.checkfield);
        end
    end
end

fprintf('Done.\n')

end