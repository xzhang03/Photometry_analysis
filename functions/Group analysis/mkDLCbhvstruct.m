function bhvstruct = mkDLCbhvstruct(DLCstruct, varargin)
% mkbhvstruct makes a behavioral-specific structure
% bhvstruct = mkbhvstruct(datastruct, varargin)

% Parse input
p = inputParser;

addOptional(p, 'datafield', 'dist'); % Field for data
addOptional(p, 'bhvfield', ''); % Behavioral field
addOptional(p, 'pre_space', 5); % Length of time to include before the 
                                % onset of behaviors.
addOptional(p, 'post_space', 5);    % Length of time to include after the 
                                    % offset of behaviors.
addOptional(p, 'logstarttime', false); % Log when each event starts
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

%% Initialize
% Guess how many events there might be for memory purposes
nevents = sum([DLCstruct(:).(['n', p.bhvfield])]);
bhvstruct = struct('session', 0, 'data', 0, 'length', 0, 'bhvind', 0, ...
    'order', 0, 'fps', 0);
bhvstruct = repmat(bhvstruct, [nevents, 1]);

% Record the actual number of events (two consequtive events are now
% counted as one)
nevents_real = 0;

%% loop through and parse
% Initialize
ind = 0;

for i = 1 : size(DLCstruct, 1)
    % Get behavior table
    bhv_tab_temp = chainfinder(DLCstruct(i).(p.bhvfield) > 0.5);
    
    % Update the number of true events
    nevents_real = nevents_real + size(bhv_tab_temp, 1);
    
    % Find Fs
    Fs = DLCstruct(i).fps;
    
    % Parameters
    prew = Fs * p.pre_space;
    postw = Fs * p.post_space;
    l = prew + postw + 1;
    
    % Loop through each event
    for j = 1 : size(bhv_tab_temp, 1)
        % index
        ind = ind + 1;
        
        % Fill name
        bhvstruct(ind).session = i;
        
        % Fill Fs
        bhvstruct(ind).fps = Fs;
        
        % Fill length
        bhvstruct(ind).length = bhv_tab_temp(j, 2);
        
        % Fill index
        bhvstruct(ind).bhvind = [prew + 1,...
            prew + bhvstruct(ind).length];
        bhvstruct(ind).bhvind = min(bhvstruct(ind).bhvind, l);
        
        % Fill order
        bhvstruct(ind).order = j;
        
        % Fill data
        ind_start = bhv_tab_temp(j, 1) - prew;
        ind_stop = bhv_tab_temp(j, 1) + postw;
        bhvstruct(ind).data = datasplitter(DLCstruct(i).(p.datafield), ...
                    [ind_start,ind_stop]);
                
        
        % Fill event start time
        if p.logstarttime
            bhvstruct(ind).eventtime = bhv_tab_temp(j, 1);
        end
    end
end

% Remove the extra events
bhvstruct = bhvstruct(1:nevents_real);

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