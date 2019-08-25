function Outputmat = sigchopper(inputvec, trigpts, window)
% Sigchopper triggers a input signal based on another vector plus a window.
% Points out of the range of the input signal will be marked as NaNs.
% Outputmat = sigchopper(inputvec, trigpts, window)

% Default window = 500 pts
if nargin < 3
    window = [-500, 500];
end

% Grab the number of points
npoints = length(inputvec);

% Attach a long nan-tail to input signal
if size(inputvec, 1) == 1
    inputvec = [inputvec, nan(1, window(2) + 1)];
else
    inputvec = [inputvec; nan(window(2) + 1, 1)];
end

% Initialize
Outputmat = nan(sum(abs(window)) + 1, length(trigpts));

% Loop through
for i = 1 : length(trigpts)
    if trigpts(i) <= npoints
        % Work out the indices
        startind = trigpts(i) + window(1);
        endind = trigpts(i) + window(2);
        
        if startind > 0
            Outputmat(:,i) = inputvec(startind:endind);
        else
            Outputmat(:,i) = [nan(abs(startind)+1, 1); inputvec(1:endind)];
        end
    end
end

end