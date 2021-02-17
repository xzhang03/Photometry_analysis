%% Initialize
clear
% common path
defaultpath = '\\anastasia\data\photometry';


% Loading cell
% Which data files to look at {mouse, date, run}
inputloadingcell_social =...
    {'SZ624', 210115, 1; 'SZ624', 210116, 1; 'SZ624', 210117, 0;...
    'SZ624', 210122, 1; 'SZ625', 210115, 1; 'SZ625', 210116, 1;...
    'SZ625', 210117, 0; 'SZ625', 210120, 1; 'SZ625', 210122, 1}; 
tcpCheck(inputloadingcell_social, 'checkAmat', true);

%% Make data struct
% Social
varargin_datastruct = {'loadisosbestic', false, 'defaultpath', defaultpath};
[datastruct_social, n_series_social] = mkdatastruct(inputloadingcell_social, varargin_datastruct);

%% Time to line
index = 4;
varargin_time2line = {'bhvfield', 'CloseExam', 'minlength', 0.2};
time2line_photometry(datastruct_social, index, varargin_time2line);

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', [], 'nozscore', false, 'externalsigma', [],...
    'usedff', true, 'combinedzscore', false};
datastruct_social_pp = ppdatastruct(datastruct_social, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_CloseExamstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 10, 'post_space', 10, 'trim_data', true,...
    'trim_lndata', true, 'diffmean', true, 'premean', true, 'removenantrials', true, 'nantolerance', 0};
CloseExamstruct = mkbhvstruct(datastruct_social_pp, varargin_CloseExamstruct);

%% Extract data
[bhvmat, eventlabel] = extbhvstruct(CloseExamstruct, ...
    {'useLN', false, 'pretrim', 10, 'posttrim', 10});

%% Visualize sniff-trggered data
% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', []},...
    'sortc', 'diffmean', 'sortdir', 'descend', 'heatmaprange', [-2 2],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'showX', []};
viewbhvstruct(CloseExamstruct, varargin_viewbhvstruct)
