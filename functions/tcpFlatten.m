function [flattened, f1_exp] = tcpFlatten(raw, n_points)
% tcpFlatten flattens the input signal with a single exponential
% [flattened, f1_exp] = tcpFlatten(raw, n_points)
% This function removes nans

if nargin < 2
    n_points = length(raw);
end

% Fit
x = (1 : n_points)';
f1_exp = fit(x(~isnan(raw)), raw(~isnan(raw)), 'a*exp(-b*x)+c',...
    'Lower', [-Inf, 0, 0], 'StartPoint', [0.2, 0.0001, 4]);
        
% Subtract exponential component
flattened = raw - f1_exp((1 : n_points));
end
