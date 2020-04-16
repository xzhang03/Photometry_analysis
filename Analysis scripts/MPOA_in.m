%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
% inputloadingcell_mimic = {'SZ129', 190822, 1;'SZ132', 190822, 1;...
%     'SZ129', 190826, 1;'SZ132', 190826, 1;'SZ133', 190826, 1;...
%     'SZ132', 190828, 1}; 
% tcpCheck(inputloadingcell_mimic);

inputloadingcell_paper = {'SZ129', 190822, 2; 'SZ132', 190822, 2;...
    'SZ131', 190826, 2; 'SZ133', 190826, 2;...
    'SZ132', 190828, 2; 'SZ133', 190828, 2}; % 'SZ133', 190822, 2; 
tcpCheck(inputloadingcell_paper);
%% Make data struct
% Mimic
% [datastruct_mimic, n_series_mimic] = mkdatastruct(inputloadingcell_mimic, defaultpath);

% paper
[datastruct_paper, n_series_paper] = mkdatastruct(inputloadingcell_paper, ...
    {'defaultpath', defaultpath, 'loadisosbestic', false});

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', false,...
    'usedff', true, 'dffwindow', 32};
datastruct_paper_pp = ppdatastruct(datastruct_paper, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam', 'norm_length', 10, 'pre_space',...
    2, 'post_space',6, 'trim_data', true, 'trim_lndata', true, 'diffmean', true, 'lntrim_pts', [30 130]};
bhvstruct = mkbhvstruct(datastruct_paper_pp, varargin_bhvstruct);


%% Extract data
%
[bhvmat_in, eventlabel] = extbhvstruct(bhvstruct,...
    {'useLN', false, 'pretrim', 2, 'posttrim', 6});
%}
%% Visualize sniff-trggered data
% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', []},...
    'sortc', 'diffmean', 'sortdir', 'ascend', 'heatmaprange', [-3 3],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}};
viewbhvstruct(bhvstruct, varargin_viewbhvstruct)