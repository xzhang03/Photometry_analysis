function basisstruct = GLMbasisbatch(datastruct, datafield, basis_formula, state_formula)
% GLMbasisbatch makes and organizes simple and state basis functions.
% basisstruct = GLMbasisbatch(datastruct, datafield, basis_formula, state_formula)

% No state condition
if nargin < 4
    state_formula = [];
end

% Read all the setting for simple basis functions
basis_settings = basis_formula(~strcmpi(basis_formula(:,1), 'varargins'), :);

% Read the varargins for simple basis functions
varargins = basis_formula{strcmpi(basis_formula(:,1), 'varargins'), 2};

% Number of simple basis functions
nsimple = size(basis_settings, 1);

% Number of state basis functions
nstate = size(state_formula, 1);

% Number of datasets
nset = size(datastruct, 1);

% Initialize output
basisstruct = struct('data', [], 'Fs', [], 'Length', []);
basisstruct = repmat(basisstruct, [nset, 1]);

% Loop through sets to add fields
for setind = 1 : nset
    % Fill in Fs to basis structure
    basisstruct(setind).Fs = datastruct(setind).Fs;
    
    % Fill in the data
    basisstruct(setind).data = datastruct(setind).(datafield);
    
    % Fill in length to basis structure
    basisstruct(setind).Length = length(datastruct(setind).photometry);
    
    % Doing the simple basis functions
    for simpleind = 1 : nsimple
        % Get current varargin name
        varaginname_curr = basis_settings{simpleind, 2};
                
        if ~isempty(varaginname_curr)
            % Get current varargin
            varargin_curr = varargins{strcmpi(varargins(:,1), varaginname_curr), 2};
            
            % Fill in Fs
            varargin_curr{find(strcmp(varargin_curr, 'Fs')) + 1} = datastruct(setind).Fs;
            
            % Get current event
            event_curr = basis_settings{simpleind, 1};
            
            if datastruct(setind).(['n', event_curr]) > 0
                % Fill in simple basis functions
                [basisstruct(setind).([event_curr, '_sbf']),...
                    basisstruct(setind).([event_curr, '_nsbf'])] =...
                    GLMbasisphotom(datastruct(setind).(event_curr), varargin_curr);
            else
                basisstruct(setind).([event_curr, '_sbf']) = [];
                basisstruct(setind).([event_curr, '_nsbf']) = zeros(5,1);
            end
        end
    end
    
    % Doing the state basis functions
    for stateind = 1 : nstate
        
        % Dynamic event
        dyn_event_curr = datastruct(setind).(state_formula{stateind, 1});
        
        % Static event
        sta_event_curr = datastruct(setind).(state_formula{stateind, 2});
        
        % state input
        varargin_state_curr = state_formula{stateind, 3};
        
        % State name
        statename = varargin_state_curr{find(strcmp(varargin_state_curr, 'Name')) + 1};
        
        % If both dynamic and static event occur
        if datastruct(setind).(['n',state_formula{stateind, 1}]) > 0 &&...
                datastruct(setind).(['n',state_formula{stateind, 2}]) > 0
            % Fill in state basis functions
            [basisstruct(setind).([statename, '_sbf']),...
                basisstruct(setind).([statename, '_nsbf'])] =...
                GLMmakestate(dyn_event_curr, sta_event_curr, varargin_state_curr);
        else
            basisstruct(setind).([statename, '_sbf']) = [];
            basisstruct(setind).([statename, '_nsbf']) = 0;
        end
        
    end
end

end