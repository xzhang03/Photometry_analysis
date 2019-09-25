%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
inputloadingcell_mimic = {'SZ129', 190822, 1;'SZ132', 190822, 1;...
    'SZ129', 190826, 1;'SZ132', 190826, 1;'SZ133', 190826, 1;...
    'SZ132', 190828, 1}; 
tcpCheck(inputloadingcell_mimic);

inputloadingcell_paper = {'SZ129', 190822, 2; 'SZ132', 190822, 2;...
    'SZ133', 190822, 2;'SZ131', 190826, 2; 'SZ133', 190826, 2;...
    'SZ129', 190828, 2;'SZ132', 190828, 2; 'SZ133', 190828, 2}; 
tcpCheck(inputloadingcell_paper);
