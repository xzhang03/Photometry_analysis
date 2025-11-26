function viewtrigmat(trigmat, baseline, mode)
if nargin < 3
    mode = 'subtract'; % subtract or divide
    if nargin < 2
        baseline = round(size(trigmat, 1) * 0.5);
    end
end

% Trig mat reorientation and averaing
n = size(trigmat, 2);

% Figure
for i = 1 : n
    switch mode
        case {'subtract', 's'}
            trigmat(:,i) = trigmat(:,i) - mean(trigmat(1:baseline,i));
        case {'divide', 'd'}
            trigmat(:,i) = trigmat(:,i) / mean(trigmat(1:baseline,i));
    end
end

figure
imagesc(trigmat')

end