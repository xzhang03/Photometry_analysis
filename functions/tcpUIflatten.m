function [ch1_flattened, ch2_flattened, ch1_expfit_out, ch2_expfit_out]...
    = tcpUIflatten(ch1_input, ch2_input, mode, firstpt)
% tcpUIflatten uses a flatten to let user to choose how to perform the
% trace flattening
% [ch1_flattened, ch2_flattened, ch1_expfit_out, ch2_expfit_out] = tcpUIflatten(ch1_input, ch2_input, mode, firstpt)

if nargin < 4
    firstpt = 6;
    if nargin < 3
        mode = 1;
    end
end

% Calculate the number of points
n_points = length(ch1_input);

% Make a plot
figure(101)
plot([ch1_input, ch2_input]);

% choose points
flattening_segments = questdlg('Use which part to flatten?', ...
    'Choose parts', ...
    'All', 'A segment', 'Two segments', 'All');

if strcmp(flattening_segments, 'A segment')
    % Choose region if needed
    boxui = imrect(gca);
    userbox = wait(boxui);
    delete(boxui)
    user_interval = round([userbox(1), userbox(1) + userbox(3)]);
    user_interval(1) = max(firstpt, user_interval(1));
    user_interval(2) = min(length(ch1_input), user_interval(2));

    % Calculate data that are used to flatten
    ch1_to_flatten = ch1_input(user_interval(1) : user_interval(2));
    ch2_to_flatten = ch2_input(user_interval(1) : user_interval(2));

elseif strcmp(flattening_segments, 'Two segments')
    % Choose region if needed
    boxui1 = imrect(gca);
    userbox = wait(boxui1);
    delete(boxui1)

    rectangle('Position', userbox, 'LineWidth', 3);
    int1 = round([userbox(1), userbox(1) + userbox(3)]);
    int1(1) = max(firstpt, int1(1));
    int1(2) = min(length(ch1_input), int1(2));

    % Choose region if needed
    boxui2 = imrect(gca);
    userbox = wait(boxui2);
    delete(boxui2)
    int2 = round([userbox(1), userbox(1) + userbox(3)]);
    int2(1) = max(firstpt, int2(1));
    int2(2) = min(length(ch1_input), int2(2));

    % ch1 and ch2
    ch1_to_flatten = ch1_input(int1(1) : int2(2));
    ch1_to_flatten(int1(2)+1 : int2(1)-1) = nan;
    ch2_to_flatten = ch2_input(int1(1) : int2(2));
    ch2_to_flatten(int1(2)+1 : int2(1)-1) = nan;
else
    % Load up the data that are used to flatten
    ch1_to_flatten = ch1_input(firstpt:end);
    ch2_to_flatten = ch2_input(firstpt:end);
end

% fit (ignore NaNs)
[~, ch1_expfit] = tcpFlatten(ch1_to_flatten, length(ch1_to_flatten), mode);
[~, ch2_expfit] = tcpFlatten(ch2_to_flatten, length(ch2_to_flatten), mode);

% Exponential fits
ch1_expfit_out = ch1_expfit(1 : n_points);
ch2_expfit_out = ch2_expfit(1 : n_points);

% Flatten
ch1_flattened = ch1_input - ch1_expfit_out;
ch2_flattened = ch2_input - ch2_expfit_out;

close(101);


end