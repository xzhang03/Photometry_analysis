%% Initialize
clear
% common path
defaultpath = '\\anastasia\data\photometry';


% Loading cell
% Which data files to look at {mouse, date, run}
inputloadingcell_social =...
    {'SZ598', 210107, 0; 'SZ598', 210108, 1; 'SZ598', 210109, 1;...
    'SZ599', 210107, 1; 'SZ599', 210108, 1; 'SZ599', 210109, 1;...
    'SZ600', 210107, 1; 'SZ600', 210108, 1; 'SZ600', 210109, 1;...
    'SZ601', 210107, 1; 'SZ601', 210108, 1; 'SZ601', 210109, 1;...
    'SZ602', 210107, 1; 'SZ602', 210108, 1; 'SZ602', 210109, 1;...
    'SZ603', 210107, 1; 'SZ603', 210108, 1; 'SZ603', 210109, 1}; 
tcpCheck(inputloadingcell_social, 'checkAmat', true);

%% Make data struct
% Social
varargin_datastruct = {'loadisosbestic', false, 'defaultpath', defaultpath};
[datastruct_social, n_series_social] = mkdatastruct(inputloadingcell_social, varargin_datastruct);

%% Time to line
index = 3;
varargin_time2line = {'bhvfield', 'FemInvest', 'minlength', 0.2};
time2line_photometry(datastruct_social, index, varargin_time2line);

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 50, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', [], 'nozscore', false, 'externalsigma', [0.05],...
    'usedff', false, 'combinedzscore', false};
datastruct_social_pp = ppdatastruct(datastruct_social, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_CloseExamstruct = {'datafield','photometry','bhvfield', 'FemInvest',...
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
