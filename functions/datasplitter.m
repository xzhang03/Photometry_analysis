function data_out = datasplitter(data_in, inds, dim)
% datasplitter take out data based on the (m-by-1) index vec of
% [start_index, end_index]. If the indices are out of bound, nans will be
% filled in instead.
% data_out = datasplitter(data_in, inds, dim)

% Default to going down
if nargin < 3
    dim = 1;
end

if dim == 1
    ntrials = size(data_in, 2);
else
    ntrials = size(data_in, 1);
end

% See if start index is out of bounds
if inds(1) < 1
    % nan head length
    headl = 1 - inds(1);

    % Update ind
    inds(1) = 1;
else 
    headl = 0;
end

% See if end index is out of bounds
if inds(2) > size(data_in, dim)
    
    % nan tail length
    taill = inds(2) - size(data_in, dim);

    % Update ind
    inds(2) = size(data_in, dim);
else 
    taill = 0;
end
        
% Vectorize indices
indsout = inds(1) : inds(2);


% Take out the data
switch dim
    case 1
        data_out = cat(1, nan(headl,ntrials), data_in(indsout, :),...
            nan(taill,ntrials));
    case 2
        data_out = cat(2, nan(ntrials, headl), data_in(:, indsout),...
            nan(ntrials, taill));
end

end