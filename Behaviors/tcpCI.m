function CI = tcpCI(inputloadingcell, varargin)
% Courtship index

%% Parser inputs
if nargin < 2
    varargin = {};
end

p = inputParser;
addOptional(p, 'defaultpath', '\\anastasia\data\photometry');
addOptional(p, 'window', 5);
addOptional(p, 'bhvcode', 0);

if size(varargin,1) == 1 && size(varargin,2) == 1
    varargin = varargin{:};
end

% Parse
parse(p, varargin{:});
p = p.Results;

%% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell, p.defaultpath);

if exist(fullfile(loadingcell{1}, loadingcell{3}))
    % A mat
    Astruct = load(fullfile(loadingcell{1}, loadingcell{3}));
    A = Astruct.A;
    A2 = A(A(:,1) == p.bhvcode, :);

    % T0
    t0 = A2(1,2);
    tend = t0 + p.window;

    % Remove
    remove = A2(:,2) >= tend;
    A2 = A2(~remove,:);

    % Last bout
    A2(end,3) = min(A2(end,3), tend);

    CI = sum(A2(:,3) - A2(:,2)) / p.window;
else
    disp('No A mat.')
    CI = nan;
end


end