function tcpFixTrigger(inputloadingcell, varargin)
% tcpFixTrigger fixes trig matrices by adding missing fields

% Parse input
p  = inputParser;

addOptional(p, 'defaultpath', '\\anastasia\data\photometry'); % Default photometry path

addOptional(p, 'flatten_unfiltered', false); % Use the same exponential fit to flatten the unfiltered traces

addOptional(p, 'add_opto', false); % Add opto pulses from the pre-processed data
addOptional(p, 'force_add_opto', false); % Force add/redo the opto field

addOptional(p, 'add_running', false); % Add running data
addOptional(p, 'force_add_running', false); % For ce add/redo the running fields

addOptional(p, 'reduce_opto', false); % Turn opto pulses from m-by-3 to m-by-1 arrays

addOptional(p, 'checkfield', ''); % Add a field to check if missing



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
            opto = loaded_prep.opto_pulse_table(:,2);
            
            % Add field
            loaded_trig.opto = opto;
            
            % Append and display
            save(Trig_fn, 'opto', '-append');
            fprintf('%s: added opto\n', loadingcell{i,6});
        end
    end
    
    % Add runnning
    if p.add_running
        if ~isfield(loaded_trig,'speedmat') || p.force_add_running
            % See if running file exists
            if exist(fullfile(loadingcell{i,1}, loadingcell{i,7}), 'file')
                % Load running data
                running = load(fullfile(loadingcell{i,1}, loadingcell{i,7}), 'speed');
                
                % Load number of points
                n_points = load(fullfile(loadingcell{i,1}, loadingcell{i,4}), 'n_points');
                n_points = n_points.n_points;
                
                % Load triggered_tmp
                l = loaded_trig.l;
                n_optostims = loaded_trig.n_optostims;
                inds = loaded_trig.inds;
                
                % Upsample running data
                speed_upsampled = TDresamp(running.speed', 'resample',...
                    n_points/length(running.speed));

                % Fix the number of points if needed
                if length(speed_upsampled) > n_points
                    speed_upsampled = speed_upsampled(1:n_points);
                elseif length(speed_upsampled) < n_points
                    speed_upsampled(end:end + n_points - length(speed_upsampled)) = 0;
                end

                % Initialize a triggered speed matrix
                speedmat = zeros(l, n_optostims);
                for j = 1 : n_optostims
                    speedmat(:,j) = speed_upsampled(inds(j,1) : inds(j,2));
                end

                % Calculate the average triggered results
                speedmat_avg = mean(speedmat,2);
                
                % Append and display
                save(Trig_fn, 'speedmat', 'speedmat_avg', '-append');
                fprintf('%s: added running\n', loadingcell{i,6});
            else
                speedmat = [];
                speedmat_avg = [];
                
                % Append and display
                save(Trig_fn, 'speedmat', 'speedmat_avg', '-append');
                fprintf('%s: added empty running matricies\n', loadingcell{i,6});
            end
            
            % Add field
            loaded_trig.speedmat = speedmat;
            loaded_trig.speedmata_avg = speedmat_avg;
            
            
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