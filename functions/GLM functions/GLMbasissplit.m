function [basis_train, basis_test] = GLMbasissplit(basisstruct, varargin)
% GLMbasissplit splits up the dataset according to input parameters
% [basis_train, basis_test] = GLMbasissplit(basisstruct, varargin)

% Parse input
p = inputParser;

addOptional(p, 'train_mat', []);    % In an m-by-n matrix of 0 and 1, where
                                    % m is the number of datasets, and n is
                                    % the number of chunks. 1 means include
                                    % and 0 means omit.
addOptional(p, 'test_mat', []); % In an m-by-n matrix of 0 and 1, where m 
                                % is the number of datasets, and n is the 
                                % number of chunks. 1 means include and 0 
                                % means omit.

% Unpack if needed
if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

% Check that the mats make sense
if (size(p.train_mat, 1) ~= size(p.test_mat, 1)) || (size(p.train_mat, 2) ~= size(p.test_mat, 2))
    error('Training and testing matrices must have the same size.');
elseif size(p.train_mat, 1) ~= size(basisstruct, 1)
    error('Traning and testing matrices must have the same numer of samples as the basis function structure.');
end

% Chunk sizes
chunkn = size(p.train_mat, 2);
chunksz = ceil([basisstruct(:).Length] / chunkn);

% Make a plan for chunking as a tensor
chunkplan = nan(chunkn, 2, size(basisstruct, 1));

% Loop through to make plans
for i = 1 : size(basisstruct, 1)
    % Initiation indices
    chunkplan(:,1,i) = 1 : chunksz(i) : basisstruct(i).Length;
    
    if mod(basisstruct(i).Length, chunksz(i)) == 0
        % Termination indices
        chunkplan(:,2,i) = chunksz(i) : chunksz(i) : basisstruct(i).Length;
    else
        % Termination indices
        chunkplan(1:end-1,2,i) = chunksz(i) : chunksz(i) : basisstruct(i).Length;
        
        % Make sure the residual is right
        chunkplan(end, 2, i) = mod(basisstruct(i).Length, chunksz(i)) +...
            chunksz(i) * (chunkn - 1);
    end
    
end

% Initialize the output structures
basis_train = basisstruct;
basis_test = basisstruct;

% Find basisfunctions fields
fieldnames_list = fieldnames(basisstruct);
basisfields =  endsWith(fieldnames_list,'_sbf');
basisfield_names = fieldnames_list(basisfields);

% Loop through to take out the data
for i = 1 : size(basisstruct, 1)
    % Current chunk plan
    chunkplan_curr = chunkplan(:,:,i);
    
    % chunk plan for training and testing set
    chunkplan_train = chunkplan_curr(p.train_mat(i, :) > 0, :);
    chunkplan_test = chunkplan_curr(p.test_mat(i, :) > 0, :);
    
    % Split data
    basis_train(i).data = datasplitter(basisstruct(i).data, chunkplan_train, 1);
    basis_test(i).data = datasplitter(basisstruct(i).data, chunkplan_test, 1);
    
    % Calculate lengths
    basis_train(i).Length = sum(chunkplan_train(:,2) - chunkplan_train(:,1) + 1);
    basis_test(i).Length = sum(chunkplan_test(:,2) - chunkplan_test(:,1) + 1);
    
    % Split basis functions
    for j = 1 : length(basisfield_names)
        if ~isempty(basisstruct(i).(basisfield_names{j}))
            % Training set
            basis_train(i).(basisfield_names{j}) =...
                datasplitter(basisstruct(i).(basisfield_names{j}), chunkplan_train, 1);

            % Testing set
            basis_test(i).(basisfield_names{j}) =...
                datasplitter(basisstruct(i).(basisfield_names{j}), chunkplan_test, 1);
        end
    end
end
end