%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
inputloadingcell = {'SZ129', 190707, 2; 'SZ132', 190720, 2;...
                    'SZ133', 190709, 2; 'SZ133', 190720, 2;...
                    'SZ133', 190720, 3};


%% Make data struct
[datastruct, n_series] = mkdatastruct(inputloadingcell, defaultpath);

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 5, 'smooth_window', 5, 'zscore_badframes', 1 : 10,...
    'First_point', 25, 'BlankTime', 60, 'merging', [0 0 0 1 1],...
    'combinedzscore', false};
datastruct_pp = ppdatastruct(datastruct, varargin_pp);

%% Add a new mount-introm field
% Inputs
varargin_stitch = {'Name', 'MI', 'Event1', 'Mount', 'Event2', 'Introm',...
    'window', 2, 'keepjustEvent1', false, 'keepjustEvent2', true};
datastruct_pp = afdatastruct(datastruct_pp, varargin_stitch);

% Inputs for mount_introm_transfer field
varargin_stitch2 = {'Name', 'MIT', 'Event1', 'MI', 'Event2', 'Transfer',...
    'window', 2, 'keepjustEvent1', true, 'keepjustEvent2', false};
datastruct_pp = afdatastruct(datastruct_pp, varargin_stitch2);
%% GLM
% A different script
% introm_GLM;

%% Make an intromission construct
% Input for introm structure
varargin_bhvstruct = {'bhvfield', 'MI', 'norm_length', 10, 'pre_space',...
    20, 'post_space',50, 'trim_data', true, 'trim_lndata', true};
bhvstruct = mkbhvstruct(datastruct_pp, varargin_bhvstruct);

%% Visualize intromission-trggered data
% Input
varargin_viewbhvstruct =...
    {'keepc', {'rorder', [1 2 3]; 'session', []},...
    'sortc', 'rorder', 'sortdir', 'ascend', 'heatmaprange', [-3 3],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}};
viewbhvstruct(bhvstruct, varargin_viewbhvstruct)
