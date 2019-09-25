function bhvstruct = mkbhvstruct(datastruct, varargin)
% mkbhvstruct makes a behavioral-specific structure
% bhvstruct = mkbhvstruct(datastruct, varargin)

% Parse input
p = inputParser;

addOptional(p, 'datafield', 'photometry'); % Field for data
addOptional(p, 'bhvfield', ''); % Behavioral field
addOptional(p, 'norm_length', 10);  % Length to normalize to (in seconds).
                                    % This length is only referring to the
                                    % behavior.
addOptional(p, 'pre_space', 5); % Length of time to include before the 
                                % onset of behaviors.
addOptional(p, 'post_space', 5);    % Length of time to include after the 
                                    % offset of behaviors.
addOptional(p, 'BinMethod', 'mean'); % Method for binning
addOptional(p, 'trim_data', false); % Add a field that trims all the data
                                    % to the shortest length (so they are
                                    % readily concatenatable). The
                                    % resulting data will still be aligned
                                    % at onsets.
addOptional(p, 'trim_lndata', false); % Add a field that trims all the 
                                    % length-normalized data to the shortest
                                    % length (so they are readily
                                    % concatenatable). The resulting data
                                    % will still be aligned at onsets and
                                    % offsets.
                                     
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Initialize
bhvstruct = struct('session', 0, 'data', 0, 'ln_data', 0, 'bhvind', [], ...
    'lnbhvind', [], 'length', 0, 'order', 0, 'rorder', 0, 'Fs', 0, 'ln_Fs',...
    0);
nevents = sum([datastruct(:).(['n', p.bhvfield])]);
bhvstruct = repmat(bhvstruct, [nevents, 1]);

% Record the actual number of events (two consequtive events are now
% counted as one)
nevents_real = 0;

% loop through and parse
ind = 0;

% Record trim for length-normalized data
triml_ln = inf;
trimr_ln = inf;

for i = 1 : size(datastruct, 1)
    % Get behavior table
    bhv_tab_temp = chainfinder(datastruct(i).(p.bhvfield) > 0.5);
    
    % Update the number of true events
    nevents_real = nevents_real + size(bhv_tab_temp, 1);
    
    % Loop through each event
    for j = 1 : size(bhv_tab_temp, 1)
        % index
        ind = ind + 1;
        
        % Fill name
        bhvstruct(ind).session = i;
        
        % Fill Fs
        Fs = datastruct(i).Fs;
        bhvstruct(ind).Fs = Fs;
        
        % Fill length
        bhvstruct(ind).length = bhv_tab_temp(j, 2);
        
        % Fill order
        bhvstruct(ind).order = j;
        
        % Fill reverse order
        bhvstruct(ind).rorder = datastruct(i).(['n', p.bhvfield]) - j + 1;
        
        % Fill data
        ind_start = bhv_tab_temp(j, 1) - Fs * p.pre_space;
        ind_stop = bhv_tab_temp(j, 1) + Fs * p.post_space + bhv_tab_temp(j, 2) - 1;
        
        if ind_start > 0
            if ind_stop <= length(datastruct(i).(p.bhvfield))
                bhvstruct(ind).data = datasplitter(datastruct(i).(p.datafield), ...
                    [ind_start,ind_stop]);
            else
                fprintf('Throwing away Expt %i Event %i, because the end time is out of bounds.\n', i, j)
            end
        else
            fprintf('Throwing away Expt %i Event %i, because the start time is out of bounds.\n', i, j)
        end
        
        % Fill index
        bhvstruct(ind).bhvind = [Fs * p.pre_space + 1,...
            Fs * p.pre_space + bhvstruct(ind).length];
        
        % Fill length-normalized data
        % resampling factor
        rsfactor = p.norm_length * Fs / bhvstruct(ind).length;
        if rsfactor == 1
            bhvstruct(ind).ln_data = bhvstruct(ind).data;
        else
            bhvstruct(ind).ln_data = ...
                tcpBin(bhvstruct(ind).data, bhvstruct(ind).Fs,...
                bhvstruct(ind).Fs * rsfactor, p.BinMethod, 1, true);
        end
        
        % Fill post-binning index
        bhvstruct(ind).lnbhvind = round([Fs * p.pre_space * rsfactor + 1,...
            Fs * p.pre_space * rsfactor + p.norm_length * Fs]);
        
        % Fill post-binning Fs
        bhvstruct(ind).ln_Fs = rsfactor * Fs;
        
        % Record trims for length-normalized data
        triml_ln = min(triml_ln, bhvstruct(ind).lnbhvind(1) - 1);
        trimr_ln = min(trimr_ln, length(bhvstruct(ind).ln_data) -...
            bhvstruct(ind).lnbhvind(1));
        
    end
end


% Remove the extra events
bhvstruct = bhvstruct(1:nevents_real);

%% Trim data
if p.trim_data
    % left trim
    triml = Fs * p.pre_space;
    
    % right trim
    trimr = min([bhvstruct(:).length]) + Fs * p.post_space;
    
    % loop through and trim
    for i = 1 : nevents_real
        
        % data
        bhvstruct(i).data_trim = datasplitter(bhvstruct(i).data, [1, triml + trimr]);
        
        % index
        bhvstruct(i).data_trimind =...
            [triml + 1, min(bhvstruct(i).bhvind(2), triml + trimr)];
    end
end


%% Trim length-normalized data
if p.trim_lndata
    % loop through and trim
    for i = 1 : nevents_real

        % data
        bhvstruct(i).ln_data_trim = datasplitter(bhvstruct(i).ln_data,...
            bhvstruct(i).lnbhvind(1) + [-triml_ln, trimr_ln]);
        
        % number of points that are removed on the left
        pt_rm_l = bhvstruct(i).lnbhvind(1) - triml_ln - 1;
        
        % index
        bhvstruct(i).ln_data_trimind =...
            bhvstruct(i).lnbhvind - pt_rm_l;
    end
end