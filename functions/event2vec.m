function eventvector = event2vec(A, eventtype, timefactor)
% event2vec turns event matrix to vector. Eventtype is a numerical label
% for event type. Timefactor is used to convert times. All time points are
% rounded.

% Inputs
if nargin < 3
    timefactor = 1;
    if nargin < 2
        eventtype = 0;
    end
end

% Apply time factor (usually means to change the unit of time)
A(:,[2,3]) = A(:,[2,3]) * timefactor;
A = round(A);

% Get the number of points
eventvector = zeros(A(end),1);

% Subset event type
A2 = A(A(:,1) == eventtype,:);

for i = 1 : size(A2,1)
    eventvector(A2(i,2) : A2(i,3)) = 1;
end

end