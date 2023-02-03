function ratevec = tcpRatevec(inputvec, type, fps)
% tcpRatevec turns a binary vector into a vector of the rates of
% onsets/offsets
% type = 'onset' or 'offset'

if nargin < 3
    fps = 1;
    if nargin < 2
        type = 'onset';
    end
end

%% Convert
switch type
    case 'onset'
        v = diff(inputvec) > 0.5;
    case 'offset'
        v = diff(inputvec) < -0.5;
end

if size(v,2) == 1
    % Vertical, pad 1 zero on top
    v = cat(1, false, v);
else
    % Horizontal, pad 1 zero on left
    v = cat(2, false, v);
end

%% Time points
ts = find(v);
ratevec = zeros(size(v));
for i = 1 : length(ts)
    if i == 1
        ratevec(ts(i)) = 1 / ts(i);
    else
        ratevec(ts(i)) = 1 / (ts(i) - ts(i-1));
    end
end

%% FPS
ratevec = ratevec * fps;

end