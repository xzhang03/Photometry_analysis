function [dexexp, devhyp]  = devexp(modeled_data, actual_data)
% devexp calculates the deviance explained of fits with a null-model of y =
% 0.
% [dexexp, devhyp] = devexp(modeled_data, actual_data)

% Null deviance
dev0 = sum(actual_data .^ 2);

% model deviance
devhyp = sum((actual_data - modeled_data) .^ 2);

% Deviance explained
dexexp = (dev0 - devhyp) / dev0;



end