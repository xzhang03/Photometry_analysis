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
[datastruct_social_405, n_series_social] =...
    mkdatastruct(inputloadingcell_social, {'defaultpath', defaultpath,...
    'loadisosbestic', true});

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', false,...
    'usedff', false, 'nozscore', false, 'externalsigma', 0.0481};
datastruct_social_405_pp = ppdatastruct(datastruct_social_405, varargin_pp);
% 0.0481
%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 10, 'post_space', 10, 'trim_data', true,...
    'trim_lndata', true, 'premean2s', true};
CloseExamstruct_sat_405 = mkbhvstruct(datastruct_social_405_pp, varargin_bhvstruct);

%% Extract data
[bhvmat, eventlabel] = extbhvstruct(CloseExamstruct_sat_405,...
    {'useLN', false, 'pretrim', 10, 'posttrim', 10});

%% Visualize sniff-trggered data
% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', []},...
    'sortc', 'premean2s', 'sortdir', 'descend', 'heatmaprange', [-3 3],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'showX', 30};
viewbhvstruct(CloseExamstruct_sat_405, varargin_viewbhvstruct)
