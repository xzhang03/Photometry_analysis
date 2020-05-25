%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Loading cell
% Which data files to look at {mouse, date, run}
inputloadingcell_sat = {'SZ52', 190527, 1; 'SZ129', 190709, 2}; 

% Loading cell
% Which data files to look at {mouse, date, run}
inputloadingcell_naive = {'SZ51', 190410, 1; 'SZ51', 190410, 2;...
    'SZ52', 190411, 1; 'SZ52', 190411, 2; 'SZ51', 190417, 1; 'SZ51', 190417, 2;...
    'SZ52', 190417, 1; 'SZ52', 190417, 3; 'SZ51', 190419, 1; 'SZ52', 190419, 1;...
    'SZ52', 190523, 1; 'SZ52', 190525, 1; 'SZ52', 190525, 2; 'SZ129', 190703, 1;...
    'SZ129', 190703, 2; 'SZ131', 190703, 2; ...
    'SZ132', 190703, 2; 'SZ133', 190703, 1; 'SZ133', 190703, 2; 'SZ129', 190707, 1;...
    'SZ129', 190707, 2; 'SZ131', 190707, 1; 'SZ131', 190707, 2; 'SZ131', 190707, 1;...
    'SZ51', 190604, 1; 'SZ52', 190604, 1; 'SZ133', 190709, 2; 'SZ132', 190720, 2}; 

%% Make data struct
% Social
[datastruct_sat, n_series_sat] = mkdatastruct(inputloadingcell_sat, {'defaultpath', defaultpath});
[datastruct_naive, n_series_naive] = mkdatastruct(inputloadingcell_naive, {'defaultpath', defaultpath});

%% Postprocess data struct
% Inputs
varargin_pp = {'Fs_ds', 50, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', false,...
    'usedff', false, 'nozscore', false, 'externalsigma', []};
datastruct_naive_pp = ppdatastruct(datastruct_naive, varargin_pp);
datastruct_sat_pp = ppdatastruct(datastruct_sat, varargin_pp);

%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 10, 'post_space', 10, 'trim_data', true,...
    'trim_lndata', true, 'premean2s', true, 'logstarttime', true};
CloseExamstruct_naive = mkbhvstruct(datastruct_naive_pp, varargin_bhvstruct);
CloseExamstruct_sat = mkbhvstruct(datastruct_sat_pp, varargin_bhvstruct);

%% Match time
% Match
VecNaive = [CloseExamstruct_naive(:).eventtime]';
VecSat = [CloseExamstruct_sat(:).eventtime]';
[Naive_matchtime, Sat_matchtime] = matchbhvonsets(VecNaive, test, 50 * 2);

scatter(VecNaive(Naive_matchtime(Naive_matchtime > 0)),test(Sat_matchtime));