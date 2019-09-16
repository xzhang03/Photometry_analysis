%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
inputloadingcell_mimic = {'SZ118', 190719, 1; 'SZ114', 190806, 1; 'SZ118', 190806, 1;...
    'SZ118', 190812, 2; 'SZ114', 190822, 1; 'SZ118', 190822, 1}; 
tcpCheck(inputloadingcell_mimic);

inputloadingcell_paper = {'SZ114', 190806, 2; 'SZ118', 190806, 2; 'SZ118', 190812, 3;...
    'SZ114', 190822, 2;  'SZ118', 190822, 2}; 
tcpCheck(inputloadingcell_paper);

% Leftovers
% inputloadingcell_mimiclo = {'SZ114', 190719, 3}; 
% inputloadingcell_paperlo = {'SZ114', 190719, 2};
%% Make data struct
[datastruct_mimic, n_series_mimic] = mkdatastruct(inputloadingcell_mimic, defaultpath);
[datastruct_paper, n_series_paper] = mkdatastruct(inputloadingcell_paper, defaultpath);