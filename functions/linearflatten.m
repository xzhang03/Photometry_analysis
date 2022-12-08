function [outvec, subvec] = linearflatten(invec, pts)
% linearflatten flattens the input vector with a linear fit
% [outvec, subvec] = linearflatten(invec)

if nargin < 2
    pts = [1, length(invec)];
    p = false;
else
    p = true;
end
n_points = length(invec);

% Fit
x = (1 : n_points)';
    
if p
    xfit = x(pts(1):pts(2))';
    yfit = invec(pts(1):pts(2))';
    f1_lin = fit(xfit(~isnan(xfit))', yfit(~isnan(yfit))', 'poly1');
else
    
    f1_lin = fit(x(~isnan(invec)), invec(~isnan(invec)), 'poly1');
end

subvec  = f1_lin(x);

% Subtract slope component
outvec = invec - subvec;
    
end