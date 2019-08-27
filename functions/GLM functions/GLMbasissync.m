function basisstruct_sync = GLMbasissync(basisstruct, syncformula)
% GLMbasissync alligns the basis functions between multiple trials
% basisstruct_sync = GLMbasissync(basisstruct, syncformula)
% Sync options are: alignfront (default), alignback, chopback (keeping
% front), chop front (keeping back)

% If no sync formula, everything defaults to syncfront
if nargin < 2
    % No formula
    defaultMode = true;
    syncmode = 'alignfront';
elseif ischar(syncformula)
    % Singular formula
    defaultMode = true;
    syncmode = syncformula;
else
    defaultMode = false;
end
    
% Number of events
nevent = size(syncformula, 1);

% Number of datasets
nset = size(basisstruct, 1);

% Initialize output
basisstruct_sync = basisstruct;

% Loop through event type
for eventind = 1 : nevent
    % Grab sync mode
    if ~defaultMode
        syncmode = syncformula{eventind, 2};
    end

    if ~isempty(syncmode)
        % Grab event type
        eventtype = syncformula{eventind, 1};
        
        % Matrix of the number of basis functions
        mat_nsbf = [basisstruct(:).([eventtype, '_nsbf'])];
        
        % keep track of indices
        ind = zeros(nset, 1);
        
        for setind = 1 : nset
            % Wipe out the basis function space to be written in
            basisstruct_sync(setind).([eventtype, '_sbf']) = [];
        end
        
        % Loop through basis types (gaussian, ramp-up, ramp-down, etc.)
        for i = 1 : size(mat_nsbf, 1)
            % If there is any of that type
            if sum(mat_nsbf(i,:)) > 0
                switch syncmode
                    case 'alignfront'
                        % Number of basis functions
                        n_max = max(mat_nsbf(i,:));
                        
                        % Loop through sets
                        for setind = 1 : nset
                            % Number of basis functions that already exist
                            n_curr = mat_nsbf(i, setind);
                            
                            % Number of empty basis functions to add
                            n_add = n_max - n_curr;
                            
                            % Existing basis functions
                            basis_curr = basisstruct(setind).([eventtype, '_sbf'])...
                                (:, (ind(setind) + 1) : (ind(setind) + n_curr));
                            
                            % Add them
                            basisstruct_sync(setind).([eventtype, '_sbf']) =...
                                [basisstruct_sync(setind).([eventtype, '_sbf']),...
                                basis_curr, zeros(basisstruct(setind).Length, n_add)];
                            
                            % Update the number
                            basisstruct_sync(setind).([eventtype, '_nsbf'])(i) = n_max;
                            
                            % Update index
                            ind(setind) = ind(setind) + n_curr;
                        end
                        
                    case 'alignback'
                        % Number of basis functions
                        n_max = max(mat_nsbf(i,:));
                        
                        % Loop through sets
                        for setind = 1 : nset
                            % Number of basis functions that already exist
                            n_curr = mat_nsbf(i, setind);
                            
                            % Number of empty basis functions to add
                            n_add = n_max - n_curr;
                            
                            % Existing basis functions
                            basis_curr = basisstruct(setind).([eventtype, '_sbf'])...
                                (:, (ind(setind) + 1) : (ind(setind) + n_curr));
                            
                            % Add them
                            basisstruct_sync(setind).([eventtype, '_sbf']) =...
                                [basisstruct_sync(setind).([eventtype, '_sbf']),...
                                zeros(basisstruct(setind).Length, n_add), basis_curr];
                            
                            % Update the number
                            basisstruct_sync(setind).([eventtype, '_nsbf'])(i) = n_max;
                            
                            % Update index
                            ind(setind) = ind(setind) + n_curr;
                        end
                        
                    case 'chopback'
                        % Number of basis functions
                        n_min = min(mat_nsbf(i,:));
                        
                        % Loop through sets
                        for setind = 1 : nset
                            % Number of basis functions that already exist
                            n_curr = mat_nsbf(i, setind);
                            
                            % Existing basis functions
                            basis_curr = basisstruct(setind).([eventtype, '_sbf'])...
                                (:, (ind(setind) + 1) : (ind(setind) + n_curr));
                            
                            % Keep front
                            basisstruct_sync(setind).([eventtype, '_sbf']) =...
                                [basisstruct_sync(setind).([eventtype, '_sbf']),...
                                basis_curr(:, 1:n_min)];
                            
                            % Update the number
                            basisstruct_sync(setind).([eventtype, '_nsbf'])(i) = n_min;
                            
                            % Update index
                            ind(setind) = ind(setind) + n_curr;
                        end
                        
                    case 'chopfront'
                        % Number of basis functions
                        n_min = min(mat_nsbf(i,:));
                        
                        % Loop through sets
                        for setind = 1 : nset
                            % Number of basis functions that already exist
                            n_curr = mat_nsbf(i, setind);
                            
                            % Existing basis functions
                            basis_curr = basisstruct(setind).([eventtype, '_sbf'])...
                                (:, (ind(setind) + 1) : (ind(setind) + n_curr));
                            
                            % Keep front
                            basisstruct_sync(setind).([eventtype, '_sbf']) =...
                                [basisstruct_sync(setind).([eventtype, '_sbf']),...
                                basis_curr(:, (end - n_min + 1) : end)];
                            
                            % Update the number
                            basisstruct_sync(setind).([eventtype, '_nsbf'])(i) = n_min;
                            
                            % Update index
                            ind(setind) = ind(setind) + n_curr;
                        end
                end
            end
        end
    end
end


end