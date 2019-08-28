function [basis_train, basis_test] = GLMbasissplit(basisstruct, varargin)
% GLMbasissplit splits up the dataset according to input parameters
% [basis_train, basis_test] = GLMbasissplit(basisstruct, varargin)

% Parse input
p = inputParser;

addOptional(p, 'train_mat', []); % In an m-by-n matrix of 0 and 1, where m is the number of datasets, and n is the number of chunks. 1 means include and 0 means omit.
addOptional(p, 'test_mat', []); % In an m-by-n matrix of 0 and 1, where m is the number of datasets, and n is the number of chunks. 1 means include and 0 means omit.

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
chunksz = round([basisstruct(:).Length] / chunkn);

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
        chunkplan(end, 2, i) = basisstruct(i).Length - chunksz(i) * (chunkn - 1);
    end
    
end


end