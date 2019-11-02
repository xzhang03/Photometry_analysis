%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\behavior';

%% IO
% Which data files to look at {mouse, date, run}
% 0 day baseline (should update in the future)
baselineloadingcell = {'SZ05', 181225, 2; 'SZ05', 181225, 3; 'SZ04', 190131, 2;...
    'SZ06', 190106, 2; 'SZ07', 190119, 2}; 

i = 5;

% Make actual loading cell
loadingcell = mkloadingcell(baselineloadingcell(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

%% IO
% Which data files to look at {mouse, date, run}
% 1 day stim
stimloadingcell = {'SZ154', 190903, 2; 'SZ170', 190903, 2; 'SZ173', 191005, 1;...
    'SZ176', 191005, 1; 'SZ174', 191009, 1; 'SZ175', 191009, 1}; 

% 1 day baseline
baselineloadingcell = {'SZ119', 190614, 1; 'SZ120', 190614, 1; 'SZ122', 190615, 1;...
    'SZ121', 190616, 1; 'SZ123', 190616, 1; 'SZ126', 190617, 1}; 


i = 6

% Make actual loading cell
loadingcell = mkloadingcell(stimloadingcell(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;