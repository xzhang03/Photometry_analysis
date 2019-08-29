function datastruct = afdatastruct(datastruct, varargin)
% afdatastruct adds a field to data struct
% datastruct = afdatastruct(datastruct, varargin)

% Parse input
p = inputParser;

addOptional(p, 'Name', ''); % Field name for the new event
addOptional(p, 'Event1', ''); % Event 1's name
addOptional(p, 'Event2', ''); % Event 2's name
addOptional(p, 'window', 2); % window of tolerance (in seconds)
addOptional(p, 'keepjustEvent1', false); % Keep events that are just event 1
addOptional(p, 'keepjustEvent2', false); % Keep events that are just event 2

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% number of series
n_series = length(datastruct);



for serind = 1 : n_series
    % Window vector
    winl = p.window * datastruct(serind).Fs;
    winvec = ones(1, winl);

    % Get events
    event1 = datastruct(serind).(p.Event1);
    event2 = datastruct(serind).(p.Event2);
    
    % Convolve (and keep length consistent)
    event1_conv = conv(event1, winvec);
    event1_conv = event1_conv(1 : end-winl+1) > 0.5;
    
    % Add up the vectors
    event_new = (event1_conv + event2) > 0.5;
    
    % Get the chainmat
    chain_new = chainfinder(event_new > 0.5);
    
    % Check if there are Event1-only events
    if ~p.keepjustEvent1
        for i = 1 : size(chain_new,1)
            % Check if there is any Event 2
            startind = chain_new(i,1);
            endind = chain_new(i,1) + chain_new(i,2) - 1;
            
            if sum(event2(startind:endind)) == 0
                % Remove
                event_new(startind:endind) = 0;
            end
        end
    end
    
    % Check if there are Event2-only events
    if ~p.keepjustEvent2
        for i = 1 : size(chain_new,1)
            % Check if there is any Event 2
            startind = chain_new(i,1);
            endind = chain_new(i,1) + chain_new(i,2) - 1;
            
            if sum(event1(startind:endind)) == 0
                % Remove
                event_new(startind:endind) = 0;
            end
        end
    end
    
    % Add field
    datastruct(serind).(p.Name) = double(event_new);
    
    % Count the number of events
    datastruct(serind).(['n',p.Name]) =...
        size(chainfinder(event_new > 0.5), 1);
end

end