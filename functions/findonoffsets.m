function [onsets, offsets] = findonoffsets(data)
% findonoffsets find the onset and offset of data (presumed to be binary)
% [onsets, offsets] = findonoffsets(data)

% Onsets
onsets = find(diff(data) > 0);

% Offsets
offsets = find(diff(data) < 0);
end