%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Loading cell
% Which data files to look at {mouse, date, run}
inputloadingcell_social = {'SZ114', 190702, 1; 'SZ117', 190605, 1; 'SZ117', 190605, 2;...
    'SZ118', 190605, 1; 'SZ118', 190605, 2; 'SZ114', 190604, 1; 'SZ114', 190604, 2;...
    'SZ116', 190604, 1; 'SZ116', 190604, 2; 'SZ118', 190812, 1}; 
tcpCheck(inputloadingcell_social);

%% Make data struct
% Social
[datastruct_social, n_series_social] = mkdatastruct(inputloadingcell_social, defaultpath);

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', true,...
    'usedff', false, 'dffwindow', 40};
datastruct_social_pp = ppdatastruct(datastruct_social, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 2, 'post_space',6, 'trim_data', true,...
    'trim_lndata', true, 'diffmean', true};
bhvstruct = mkbhvstruct(datastruct_social_pp, varargin_bhvstruct);

%% Visualize sniff-trggered data
% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', [1 3 4 9 10]},...
    'sortc', 'diffmean', 'sortdir', 'ascend', 'heatmaprange', [-2 2],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}};
viewbhvstruct(bhvstruct, varargin_viewbhvstruct)
