function outvec = linearflatten(invec)
% linearflatten flattens the input vector with a linear fit
% outvec = linearflatten(invec)

n_points = length(invec);

% Fit
x = (1 : n_points)';
f1_lin = fit(x(~isnan(invec)), invec(~isnan(invec)), 'poly1');

% Subtract slope component
outvec = invec - f1_lin(x);
end