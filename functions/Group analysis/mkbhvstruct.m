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
% Things to sort
addOptional(p, 'diffmean', false);  % Add a field that is the mean of the
                                    % intra-stim mean minus the pre-stim
                                    % mean (in 2 second windows)
addOptional(p, 'premean', false);   % Add a field that is the mean fluorescence 
                                    % during the pre-stim period
addOptional(p, 'premean2s', false);   % Add a field that is the mean fluorescence 
                                    % during the 2s pre-stim period
addOptional(p, 'postmean', false);   % Add a field that is the mean fluorescence 
                                    % during the post-stim period
addOptional(p, 'diffbox', false); % Add a field that the difference in mean fluorescence
                                  % in and out of the box in
                                  % length-normalized data
addOptional(p, 'boxmean', false); % Add a field that is the mean fluorescence
                                  % in the box in length-normalized data

                                    
% nan things
addOptional(p, 'removenantrials', true);    % Remove any trials with nans in 
                                            % data. Tolerance is set by
                                            % nantolerance.
addOptional(p, 'nantolerance', 0);  % Fraction of data allowed to be nan. 
                                    % Only used if removenantrials is true.
                                     
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
%                 disp([num2str(i), ' - ', num2str(j)]);
                
                bhvstruct(ind).data = datasplitter(datastruct(i).(p.datafield), ...
                    [ind_start,ind_stop]);
                
                % Diff mean
                if p.diffmean
                    % Fill diff-mean (mean of 2s post-stim  minus mean of 2s
                    % pre-stim
                    bhvstruct(ind).diffmean =...
                        mean(bhvstruct(ind).data(Fs * p.pre_space + 1 :...
                        Fs * p.pre_space + 2 * Fs)) - ...
                        mean(bhvstruct(ind).data(Fs * p.pre_space - 2 * Fs + 1 :...
                        Fs * p.pre_space));
                end
                
                % Pre mean
                if p.premean
                    % Fill pre-mean (mean during pre-stim)
                    bhvstruct(ind).premean =...
                        mean(bhvstruct(ind).data(1 : Fs * p.pre_space));
                end
                
                % Pre mean 2s
                if p.premean2s
                    % Fill pre-mean (mean of 2s pre-stim)
                    bhvstruct(ind).premean2s =...
                        mean(bhvstruct(ind).data(Fs * p.pre_space - 2 * Fs + 1 : Fs * p.pre_space));
                end
                
                % Post mean
                if p.postmean
                    % Fill pre-mean (mean during post-stim)
                    bhvstruct(ind).postmean =...
                        mean(bhvstruct(ind).data(Fs * p.pre_space + 1 : end));
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
                
                % Calculate difference between data in and out of the
                % length-normalized boxes
                if p.diffbox
                    boxind = bhvstruct(ind).lnbhvind;
                    boxdata = bhvstruct(ind).ln_data(boxind(1):boxind(2));
                    outofboxdata = bhvstruct(ind).ln_data([1 : boxind(1) - 1,...
                        boxind(2) + 1 : end]);
                    bhvstruct(ind).diffbox = nanmean(boxdata) - nanmean(outofboxdata);
                end
                
                % Calculate mean of data in the length-normalized boxes
                if p.boxmean
                    boxind = bhvstruct(ind).lnbhvind;
                    boxdata = bhvstruct(ind).ln_data(boxind(1):boxind(2));
                    bhvstruct(ind).diffbox = nanmean(boxdata);
                end
                
                % Fill post-binning Fs
                bhvstruct(ind).ln_Fs = rsfactor * Fs;

                % Record trims for length-normalized data
                triml_ln = min(triml_ln, bhvstruct(ind).lnbhvind(1) - 1);
                trimr_ln = min(trimr_ln, length(bhvstruct(ind).ln_data) -...
                    bhvstruct(ind).lnbhvind(1));
            else
                fprintf('Throwing away Expt %i Event %i, because the end time is out of bounds.\n', i, j)
                bhvstruct(ind).data = [];
                bhvstruct(ind).ln_data = [];
            end
        else
            fprintf('Throwing away Expt %i Event %i, because the start time is out of bounds.\n', i, j)
            bhvstruct(ind).data = [];
            bhvstruct(ind).ln_data = [];
        end
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
        
        if ~isempty(bhvstruct(i).data)
            % data
            bhvstruct(i).data_trim = datasplitter(bhvstruct(i).data, [1, triml + trimr]);

            % index
            bhvstruct(i).data_trimind =...
                [triml + 1, min(bhvstruct(i).bhvind(2), triml + trimr)];
        end
    end
end


%% Trim length-normalized data
if p.trim_lndata
    % loop through and trim
    for i = 1 : nevents_real
        if ~isempty(bhvstruct(i).data)
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
end

%% Remove trials with nans
if p.removenantrials
    % vector to see if data pass the nan test
    nan_fraction = nan(nevents_real, 1);
    
    % loop through and trim
    for i = 1 : nevents_real
        nan_fraction(i) = sum(isnan(bhvstruct(i).data)) / length(bhvstruct(i).data);
    end
    
    % Remove data
    bhvstruct = bhvstruct(nan_fraction <= p.nantolerance);
end

%% Remove empty trials
% Find the empty trials
emptytrials = cellfun(@isempty, {bhvstruct(:).data});

% Remove
bhvstruct = bhvstruct(~emptytrials);

end