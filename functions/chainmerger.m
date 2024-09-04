function chainmat_out = chainmerger(chainmat_in, threshold, mode)
% chainmerger merges chains that are insufficiently far apart. Threshold is
% the length that needs to equal to NOT get merged
% Modes: 
% 1 (default): end to start
% 2          : start to start

if nargin < 3
    mode = 1;
end

%% Chain lengths
if mode == 1
    % End to start
    diffvec = cat(1, threshold+1, diff(chainmat_in(:,1)) - chainmat_in(1:end-1,2));
elseif mode == 2
    % Start to start
    diffvec = cat(1, threshold+1, diff(chainmat_in(:,1)));
else
    disp('Unknown mode. Exit.')
    return;
end

%% Find short chains
chain2 = find(diffvec >= threshold);
chain2(1:end-1,2) = chain2(1:end-1,1) + diff(chain2) - 1;
chain2(end,2) = size(chainmat_in, 1);

%% Make new chains
chainmat_out = chainmat_in(chain2(:,1), 1);
chainmat_out(:,2) = chainmat_in(chain2(:,2), 1) - chainmat_in(chain2(:,1), 1) + chainmat_in(chain2(:,2), 2);

end