function [bhvmat, eventlabel] = extbhvstruct(bhvstruct, varargin)
% mkdatastruct makes a data structure based on the input data addresses.
% [datastruct, n_series] = mkdatastruct(inputloadingcell, defaultpath)

% Parse inputs
p = inputParser;

addOptional(p, 'useLN', false); % Extract length-normalized data
addOptional(p, 'pretrim', 5); % How many seconds to leave before trimming
addOptional(p, 'posttrim', 5);  % How many seconds to leave after trimming.
                                % This number is defined as seconds after
                                % onset for non-length-normalized data and
                                % seconds after offset for
                                % length-normalized data
addOptional(p, 'nantolerance', 0);  % Fraction of data allowed to be nan 
                                    % without being taken out
                                
% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Initialize
% N
ntrials = length(bhvstruct);

% Fs (use the first entry)
Fs = bhvstruct(1).Fs;
    
% determine length
if p.useLN
    % Event length (use the first entry)
    eventl = diff(bhvstruct(1).lnbhvind) + 1;
    
    % total length
    l = eventl + (p.pretrim + p.posttrim) * Fs + 1;
    
    % Initialize label
    eventlabel = zeros(l, 1);
    eventlabel(p.pretrim * Fs + 1 : p.pretrim * Fs + eventl) = 1;
else
    % total length
    l = (p.pretrim + p.posttrim) * Fs + 1;
    
    % Initialize label
    eventlabel = zeros(l, ntrials);
end

% Behavior matrix
bhvmat = nan(l, ntrials);

%% Fill (non-length-normalized)
if ~p.useLN
    % start ind
    ind1 = bhvstruct(1).bhvind(1) - p.pretrim * Fs;
    
    for i = 1 : ntrials
%         disp(num2str(i)) % debug
        % end ind
        ind2 = bhvstruct(i).bhvind(1) + p.posttrim * Fs;
        
        % See if out of bounds
        if ind2 > length(bhvstruct(i).data)
            % nan tail length
            taill = ind2 - length(bhvstruct(i).data);
            
            % Update ind
            ind2 = length(bhvstruct(i).data);
        else 
            taill = 0;
        end
        
        % Fill
        bhvmat(:, i) = [bhvstruct(i).data(ind1:ind2); nan(taill, 1)];
        
        % Event label
        eventlabel(p.pretrim * Fs + 1 : ...
            min(bhvstruct(i).bhvind(2),l)...
            - bhvstruct(i).bhvind(1) + p.pretrim * Fs + 1, i) = 1;
    end
end

%% Fill (length-normalized)
if p.useLN
    for i = 1 : ntrials
%         disp(num2str(i)) % debug
        
        % start ind
        ind1 = bhvstruct(i).lnbhvind(1) - p.pretrim * Fs;
        
        % See if out of bounds
        if ind1 < 1
            % nan head length
            headl = 1 - ind1;
            
            % Update ind
            ind1 = 1;
        else 
            headl = 0;
        end
        
        % end ind
        ind2 = bhvstruct(i).lnbhvind(2) + p.posttrim * Fs + 1;
        
        % See if out of bounds
        if ind2 > length(bhvstruct(i).ln_data)
            % nan tail length
            taill = ind2 - length(bhvstruct(i).ln_data);
            
            % Update ind
            ind2 = length(bhvstruct(i).ln_data);
        else 
            taill = 0;
        end
        
        % Fill
        bhvmat(:, i) = [nan(headl, 1); bhvstruct(i).ln_data(ind1:ind2); nan(taill, 1)];
    end
end

%% Get rid of nan trials
if p.nantolerance < 1
    % Fractions of trials to be nan in each case
    nanfraction = mean(isnan(bhvmat), 1);
    
    % Pass or fail
    passvec = nanfraction <= p.nantolerance;
    
    % Remove the out of bount trials
    bhvmat = bhvmat(:, passvec);
    
end
end