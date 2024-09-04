function trace = chainrestorer(chainmat, imax)
% chainrestorer does the opposite as chainfinder. It makes a trace based on
% chain inputs;

if nargin < 2
    imax = chainmat(end,1) + chainmat(end,2) - 1;
end

% Make chain
n = size(chainmat, 1);
trace = zeros(imax, 1);
for i = 1 : n
    trace(chainmat(i,1) : chainmat(i,1)+chainmat(i,2)-1) = 1;
end

end