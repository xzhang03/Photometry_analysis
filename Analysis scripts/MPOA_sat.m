%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Loading cell
% Which data files to look at {mouse, date, run}
inputloadingcell_social = {'SZ52', 190527, 1; 'SZ129', 190709, 2}; 
tcpCheck(inputloadingcell_social);

%% Make data struct
% Social
[datastruct_social, n_series_social] = mkdatastruct(inputloadingcell_social, {'defaultpath', defaultpath});

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', false,...
    'usedff', false, 'externalsigma', [], 'nozscore', false};
datastruct_social_pp = ppdatastruct(datastruct_social, varargin_pp);

% 0.0481
% 0.0271 is another combined sigma
%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 5, 'post_space', 5, 'trim_data', true,...
    'trim_lndata', true, 'premean2s', true};
bhvstruct = mkbhvstruct(datastruct_social_pp, varargin_bhvstruct);

%% Extract data
[bhvmat_sat, eventlabel_sat] = extbhvstruct(bhvstruct,...
    {'useLN', false, 'pretrim', 10, 'posttrim', 10});

%% Visualize sniff-trggered data
showvec = [1 2 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 33 34 35 36 37 38 39 40 41 42 43 ];

% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', []},...
    'sortc', 'premean2s', 'sortdir', 'descend', 'heatmaprange', [-2 2],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'showX', showvec};
viewbhvstruct(bhvstruct, varargin_viewbhvstruct)
