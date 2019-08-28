function data_out = datasplitter(data_in, ind_matrix, dim)
% datagrabber take out data based on the (m-by-2) index matrix of
% [start_index, end_index].
% data_out = datagrabber(data_in, ind_matrix, dim)

% Default to going down
if nargin < 3
    dim = 1;
end

% Initialize a index cell
ind_cell = cell(size(ind_matrix, 1), 1);

% Get the indices
for i = 1 : size(ind_matrix, 1)
    ind_cell{i} = (ind_matrix(i,1) : ind_matrix(i,2))';
end

% Get the indices in vector form
inds = cell2mat(ind_cell);

% Take out the data
switch dim
    case 1
        data_out = data_in(inds, :);
    case 2
        data_out = data_in(:, inds);
end

end