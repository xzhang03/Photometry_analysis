function plotStaggered(M, labels, spacingFactor)
% PLOTSTAGGERED  Plot the n columns of an [m x n] matrix as vertically
% staggered traces in a single panel.
%   plotStaggered(M)
%   plotStaggered(M, labels)                 % labels: string array, one per column
%   plotStaggered(M, labels, spacingFactor)  % spacing as multiple of data range (default 1.2)

    [m, n] = size(M);
    if nargin < 3 || isempty(spacingFactor), spacingFactor = 1.2; end

    % Spacing: a bit larger than the biggest peak-to-peak range across columns
    rng = max(max(M, [], 1, 'omitnan') - min(M, [], 1, 'omitnan'));
    if rng == 0 || isnan(rng), rng = 1; end
    offset = spacingFactor * rng;

    x = (1:m)';
    figure; hold on;
    yt = zeros(1, n);
    for k = 1:n
        shift = (k-1) * offset;
        plot(x, M(:,k) + shift, 'LineWidth', 1);
        yt(k) = mean(M(:,k), 'omitnan') + shift;   % tick at each trace's mean level
    end
    hold off;

    yticks(yt);
    if nargin >= 2 && ~isempty(labels)
        yticklabels(labels);
    end
    xlim([1 m]); xlabel('Row index'); box on;
end