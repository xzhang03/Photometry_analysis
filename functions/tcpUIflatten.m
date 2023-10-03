function [ch1_flattened, ch2_flattened, ch1_expfit_out, ch2_expfit_out]...
    = tcpUIflatten(ch1_input, ch2_input)
% tcpUIflatten uses a flatten to let user to choose how to perform the
% trace flattening
% [ch1_flattened, ch2_flattened, ch1_expfit_out, ch2_expfit_out] = tcpUIflatten(ch1_input, ch2_input)

% Calculate the number of points
n_points = length(ch1_input);

% Make a plot
figure(101)
plot([ch1_input, ch2_input]);

% choose points
flattening_segments = questdlg('Use which part to flatten?', ...
    'Choose parts', ...
    'All', 'A segment', 'All');

if strcmp(flattening_segments, 'A segment')
    % Choose region if needed
    boxui = imrect(gca);
    userbox = wait(boxui);
    delete(boxui)
    user_interval = round([userbox(1), userbox(1) + userbox(3)]);
    user_interval(1) = max(1, user_interval(1));
    user_interval(2) = min(length(ch1_input), user_interval(2));

    % Calculate data that are used to flatten
    ch1_to_flatten = ch1_input(user_interval(1) : user_interval(2));
    ch2_to_flatten = ch2_input(user_interval(1) : user_interval(2));

else
    % Load up the data that are used to flatten
    ch1_to_flatten = ch1_input;
    ch2_to_flatten = ch2_input;
end

% fit (ignore NaNs)
[~, ch1_expfit] = tcpFlatten(ch1_to_flatten);
[~, ch2_expfit] = tcpFlatten(ch2_to_flatten);

% Exponential fits
ch1_expfit_out = ch1_expfit(1 : n_points);
ch2_expfit_out = ch2_expfit(1 : n_points);

% Flatten
ch1_flattened = ch1_input - ch1_expfit_out;
ch2_flattened = ch2_input - ch2_expfit_out;

close(101);


end