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
[datastruct_social, n_series_social] = mkdatastruct(inputloadingcell_social,...
    {'defaultpath', defaultpath, 'loadisosbestic', false});

%% Time to line
index = 10;
varargin_time2line = {'bhvfield', 'CloseExam', 'minlength', 0.2};
time2line_photometry(datastruct_social, index, varargin_time2line);

%%
%{
% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell_social, defaultpath);
% Load behavior things
loaded = load (fullfile(loadingcell{index,1}, loadingcell{index,3}), 'A');
A2 = loaded.A;
A2(:,2:3) = A2(:,2:3) * 60;

%%
A2(:,2:3) = A2(:,2:3) / 60;
disp( inputloadingcell_social(index,:))
time2mat(A2, loadingcell{index,1});
%}
%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', 60, 'combinedzscore', false,...
    'usedff', true, 'dffwindow', 32, 'externalsigma', [], 'nozscore', false};
datastruct_social_pp = ppdatastruct(datastruct_social, varargin_pp);

% 0.2327
%% Make a sniffing construct
% Input for introm structure
varargin_bhvstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 5, 'post_space', 5, 'trim_data', true,...
    'trim_lndata', true, 'postmean', true, 'removenantrials', true};
bhvstruct = mkbhvstruct(datastruct_social_pp, varargin_bhvstruct);
%% Extract data
%
[bhvmat, eventlabel] = extbhvstruct(bhvstruct,...
    {'useLN', false, 'pretrim', 10, 'posttrim', 10});
%}
%% Visualize sniff-trggered data
% Input
% showvec = [1,3,4,6,7,8,10,11,12,13,16,19,31,34,38,39,41,49,52,54,56,57,60,78,88,91,92];
showvec = [1,3,4,6,7,8,9,10,11,12,13,15,16,17,18,19,28,29,30,31,34,36,37,38,...
    39,40,41,45, 48,49,50,52,54,56,57,60,63,64,65,67,68,70,72,74,78,82,...
    88,89,90,91,92];
varargin_viewbhvstruct =...
    {'keepc', {'session', [1 2 3 4 5 6 7 8 9]},...
    'sortc', 'postmean', 'sortdir', 'descend', 'heatmaprange', [-3 3],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'showX', showvec};
viewbhvstruct(bhvstruct, varargin_viewbhvstruct)
