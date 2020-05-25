function [Vec1_match, Vec2_keep] = matchbhvonsets(VecMatch, VecRef, tolerance)
% matchbhvonsets matches and subselects entries of two vectors with preset
% tolerance. Vec1_match is index of the input matching vector. Vec2_keep is
% a boolean vector on whether a match was found.
% [Vec1_match, Vec2_keep] = matchbhvonsets(Vec2match, VecRef, tolerance)

% Shuffle Vector to avoid bias
randorder = randperm(length(VecMatch));
VecMatch = VecMatch(randorder);

% Initialize
Vec1_matchshuffle = zeros(size(VecRef));
Vec2_keep = zeros(size(VecRef));

for i = 1 : length(VecRef)
    % Calculate distance
    dis = abs(VecMatch - VecRef(i));
    
    if any(dis <= tolerance)
        % Find which points has the smallest distance
        [~, ind] = min(dis);
        Vec1_matchshuffle(i) = ind;
        Vec2_keep(i) = 1;
    end
end

% Unshuffle
Vec1_match = zeros(size(Vec1_matchshuffle));
for i = 1 : length(Vec1_match)
    if Vec1_matchshuffle(i) > 0
        Vec1_match(i) = randorder(Vec1_matchshuffle(i));
    end
end

% Output
Vec2_keep = Vec2_keep > 0;
end