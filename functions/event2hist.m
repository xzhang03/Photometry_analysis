function [Y, X] = event2hist(A, timebounds, timefactor)
% event2hist makes histogram of events. Timefactor is used to convert times
% . All time points are rounded.

% Inputs
if nargin < 3
    timefactor = 1;
    if nargin < 2
        timebounds = [-1 0.5];
    end
end

% Apply time factor (usually means to change the unit of time)
A = A * timefactor;
A = round(A);

% Apply time factor to bounds
timebounds = round(timebounds * timefactor);

% Intialize data
X = (timebounds(1) : 1 : timebounds(2))';
Y = zeros(length(X),1);

% Cut off out-of-bound points
A(:,1) = max(timebounds(1), A(:,1));
A(:,2) = min(timebounds(2), A(:,2));

% Align points
A = A - timebounds(1) + 1;

% Loop through
for i = 1 : size(A,1)
    Y(A(i,1) : A(i,2)) = Y(A(i,1) : A(i,2)) + 1;
end

% Change Y to ratios
Y = Y / size(A,1);

% Plot
figure
plot(X,Y)
end