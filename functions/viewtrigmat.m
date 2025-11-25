function viewtrigmat(trigmat, baseline)
if nargin < 2
    baseline = round(size(trigmat, 1) * 0.5);
end

% Trig mat reorientation and averaing
n = size(trigmat, 2);

% Figure
for i = 1 : n
    trigmat(:,i) = trigmat(:,i) - mean(trigmat(1:baseline,i));
end

figure
imagesc(trigmat')

end