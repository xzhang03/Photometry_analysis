%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
% inputloadingcell_mimic = {'SZ118', 190719, 1; 'SZ114', 190806, 1; 'SZ118', 190806, 1;...
%     'SZ118', 190812, 2; 'SZ114', 190822, 1; 'SZ118', 190822, 1}; 
% tcpCheck(inputloadingcell_mimic);

inputloadingcell_paper = {'SZ114', 190806, 2; 'SZ118', 190806, 2; 'SZ118', 190812, 3;...
    'SZ114', 190822, 2; 'SZ118', 190822, 2}; 
tcpCheck(inputloadingcell_paper);

% Leftovers
% inputloadingcell_mimiclo = {'SZ114', 190719, 3}; 
% inputloadingcell_paperlo = {'SZ114', 190719, 2};
%% Make data struct
% Mimic
% [datastruct_mimic, n_series_mimic] = mkdatastruct(inputloadingcell_mimic, defaultpath);

% paper
[datastruct_paper, n_series_paper] = mkdatastruct(inputloadingcell_paper,...
    {'defaultpath', defaultpath, 'loadisosbestic', false});

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', false,...
    'usedff', true, 'dffwindow', 32, 'nozscore', false, 'externalsigma', []};
datastruct_paper_pp = ppdatastruct(datastruct_paper, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 2, 'post_space', 6, 'trim_data', true,...
    'trim_lndata', true, 'diffmean', true, 'lntrim_pts', [30 130]};
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
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'ShowX', 57};
viewbhvstruct(bhvstruct, varargin_viewbhvstruct)