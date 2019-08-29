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
    'First_point', 15, 'BlankTime', 20, 'merging', [0 0 0 1 1]};
datastruct_pp = ppdatastruct(datastruct, varargin_pp);

%% GLM
% A different script
% introm_GLM;

%% Make an intromission construct
% Input for introm structure
varargin_introm = {'bhvfield', 'Introm', 'norm_length', 10, 'pre_space',...
    10, 'post_space',20, 'trim_data', true, 'trim_lndata', false};
intromstruct = mkbhvstruct(datastruct_pp, varargin_introm);

%% Visualize intromission-trggered data
data2view = [intromstruct(:).data_trim]';
[~, order] = sort([intromstruct(:).order], 'ascend');
imagesc(data2view(order, :))