%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\behavior';

%% 0 day no stim
% Which data files to look at {mouse, date, run}
% 0 day baseline (should update in the future)
baselineloadingcell = {'SZ438', 200623, 2; 'SZ439', 200623, 2; 'SZ440', 200623, 2;...
    'SZ448', 200623, 2; 'SZ439', 200623, 2; 'SZ441', 200625, 2};

i = 5;

% Make actual loading cell
loadingcell = mkloadingcell(baselineloadingcell(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

%% 0 day axon
% 0 day stim axons
stimloadingcell_axon = {'SZ176', 191004, 1; 'SZ174', 191007, 1; 'SZ175', 191007, 1;...
    'SZ219', 191204, 1; 'SZ216', 191212, 1; 'SZ221', 191213, 1};

i = 6;

% Make actual loading cell
loadingcell = mkloadingcell(stimloadingcell_axon(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

%% 0 day soma
% 0 day stim somas
stimloadingcell_soma = {'SZ229', 191221, 1; 'SZ230', 191221, 1;};

i = 2;

% Make actual loading cell
loadingcell = mkloadingcell(stimloadingcell_soma(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

%% 1 day no stim
% 1 day baseline
baselineloadingcell = {'SZ119', 190614, 1; 'SZ120', 190614, 1; 'SZ122', 190615, 1;...
    'SZ121', 190616, 1; 'SZ123', 190616, 1; 'SZ126', 190617, 1}; 
i = 1;

% Make actual loading cell
loadingcell = mkloadingcell(baselineloadingcell(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

%% 1 day axon
% Which data files to look at {mouse, date, run}
% 1 day stim
stimloadingcell = {'SZ154', 190903, 2; 'SZ170', 190903, 2; 'SZ173', 191005, 1;...
    'SZ176', 191005, 1; 'SZ174', 191009, 1; 'SZ175', 191009, 1; 'SZ219', 191205, 1;...
    'SZ216', 191213, 1; 'SZ221', 191214, 1}; 

i = 9;

% Make actual loading cell
loadingcell = mkloadingcell(stimloadingcell(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

%% 1 day soma
% Which data files to look at {mouse, date, run}
% 1 day stim
stimloadingcell = {'SZ229', 191122, 1; 'SZ230', 191122, 1}; 

i = 2;

% Make actual loading cell
loadingcell = mkloadingcell(stimloadingcell(i,:),defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;