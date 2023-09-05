function [flattened, f1_exp] = tcpFlatten(raw, n_points, mode)
% tcpFlatten flattens the input signal with a single exponential
% [flattened, f1_exp] = tcpFlatten(raw, n_points, mode)
% This function removes nans
% Modes:
% 1. a*exp(-b*x)+c [default]
% 2. a*exp(-b*x)
% 3. a*exp(-b*x)+c*exp(-d*x)

if nargin < 3
    mode = 1;
    if nargin < 2
        n_points = length(raw);
    end
end

% Fit
x = (1 : n_points)';
switch mode
    case 1
        f1_exp = fit(x(~isnan(raw)), raw(~isnan(raw)), 'a*exp(-b*x)+c',...
            'Lower', [-Inf, 0, 0], 'StartPoint', [0.2, 0.0001, 4]);
    case 2
        f1_exp = fit(x(~isnan(raw)), raw(~isnan(raw)), 'a*exp(-b*x)',...
            'Lower', [-Inf, 0], 'StartPoint', [0.2, 0.0001]);
    case 3
        f1_exp = fit(x(~isnan(raw)), raw(~isnan(raw)), 'a*exp(-b*x) + c*exp(-d*x)',...
            'Lower', [0, 0, 0, 0], 'StartPoint', [0.2, 0.0001, 0.2, 0.0001]);
end
        
% Subtract exponential component
flattened = raw - f1_exp((1 : n_points));
end
