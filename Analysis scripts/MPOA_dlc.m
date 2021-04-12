%% Initialize
clear
% common path
defaultpath = '\\anastasia\data\photometry';

inputloadingcell_naive = {'SZ49', 190410, 1; 'SZ51', 190419, 1; 'SZ51', 190417, 1;...
    'SZ51', 190417, 2; 'SZ51', 190410, 1; 'SZ51', 190410, 2; 'SZ51', 190604, 1;...
    'SZ52', 190419, 1; 'SZ52', 190417, 1; 'SZ52', 190417, 3; 'SZ52', 190411, 1;...
    'SZ52', 190411, 2; 'SZ52', 190523, 1; 'SZ52', 190525, 1; 'SZ52', 190525, 2;...
    'SZ52', 190604, 1; 'SZ129', 190703, 1; 'SZ129', 190703, 2; 'SZ129', 190707, 1;...
    'SZ129', 190707, 2; 'SZ131', 190707, 1; 'SZ131', 190707, 2;...
    'SZ132', 190703, 2; 'SZ132', 190720, 2; 'SZ133', 190703, 1; 'SZ133', 190703, 2;...
    'SZ133', 190709, 2};
inputloadingcell_naive([2, 12, 17, 18, 27],:) = [];
tcpCheck(inputloadingcell_naive, 'checkAmat', true, 'checkDLC', true);

inputloadingcell_sat = {'SZ52', 190527, 1; 'SZ129', 190709, 2; }; 
tcpCheck(inputloadingcell_sat, 'checkAmat', true);

%% Make DLC struct
% Social
varargin_DLCstruct = {'sourcetype', 'table', 'defaultpath', defaultpath,...
    'speedcolumn', 5, 'distcolumn', 3, 'fps', 30, 'confcolumn', 8};
[DLCstruct_naive, n_seriesnaivel] = mkDLCstruct(inputloadingcell_naive, varargin_DLCstruct);

%% Postprocess DLC struct
varargin_ppDLC = {'smooth_window', 3, 'conf_thresh', 0.4, 'Fs_ds', 5};
DLCstruct_naive_pp = ppDLCstruct(DLCstruct_naive, varargin_ppDLC);

%% Make a sniffing DLC construct
% Input for introm structure
varargin_CloseExamDLCstruct = {'datafield','dist','bhvfield', 'CloseExam',...
    'pre_space', 5, 'post_space', 5, 'removenantrials', true, 'nantolerance', 0.2,...
    'logstarttime', true};
CloseExamDLCstruct = mkDLCbhvstruct(DLCstruct_naive_pp, varargin_CloseExamDLCstruct);

%% Visualize DLC data
t= {CloseExamDLCstruct(:).data};
t2 = cell2mat(t);
plot(-25:25, nanmean(t2,2));

%% Look at bhv struct
session = 5;
sessionvec = cell2mat({CloseExamDLCstruct(:).session});
tmpdlcstruct = CloseExamDLCstruct(sessionvec == session);
tmpdlccell = {tmpdlcstruct(:).data};
tmpdlcmat = cell2mat(tmpdlccell);
plot(-50:50, nanmean(tmpdlcmat,2))

%% Make data struct
% Social
varargin_datastruct = {'loadisosbestic', false, 'defaultpath', defaultpath};
[datastruct_naive, n_series_social] = mkdatastruct(inputloadingcell_naive, varargin_datastruct);

%% Time to line
index = 11;
varargin_time2line = {'bhvfield', 'CloseExam', 'minlength', 0.2};
time2line_photometry(datastruct_naive, index, varargin_time2line);

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 5, 'smooth_window', 3, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', [], 'nozscore', false, 'externalsigma', [],...
    'usedff', true, 'combinedzscore', false};
datastruct_naive_pp = ppdatastruct(datastruct_naive, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_CloseExamstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 5, 'pre_space', 5, 'post_space', 10, 'trim_data', true,...
    'trim_lndata', false, 'diffmean', false, 'premean', false, 'removenantrials', true,...
    'logstarttime', true, 'nantolerance', 0.2};
CloseExamstruct = mkbhvstruct(datastruct_naive_pp, varargin_CloseExamstruct);

%% Correlation
corrDLCbhvstruct(CloseExamstruct, CloseExamDLCstruct, {'keepc', {'session', [4]}});
