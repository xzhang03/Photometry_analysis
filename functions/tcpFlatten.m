function [flattened, f1_exp] = tcpFlatten(raw, n_points)
% tcpFlatten flattens the input signal with a single exponential
% [flattened, f1_exp] = tcpFlatten(raw, n_points)

if nargin < 2
    n_points = length(raw);
end

% Fit
f1_exp = fit((1 : n_points)', raw, 'exp1');
        
% Subtract exponential component
flattened = raw - f1_exp((1 : n_points));
end
