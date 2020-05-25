%{
keep A B C
% Initialize
datastruct_social = struct('photometry', 0, 'Fs', 0,...
    'CloseExam', 0,'nCloseExam', 1, 'Approach', 0, 'nApproach', 1);
datastruct_social = repmat(datastruct_social, [88, 1]);

for i = 1 : 88
    datastruct_social(i).photometry = [A(:,i); nan(500, 1)];
    datastruct_social(i).Fs = 50;
    datastruct_social(i).CloseExam = zeros(1501,1);
    datastruct_social(i).Approach = zeros(1501,1);
    sniffdur = round(B(randi(113)) * 60 * 50 / 3);

    datastruct_social(i).CloseExam(501 : 500 + sniffdur) = 1;
    datastruct_social(i).Approach(500 - C(i) : 500) = 1;

end
%}
%%
%{
Xs = zeros(88,1);
for i = 1 : 88
    plot(1:1001, A(:,i), [500 500], [0 1]);
    [x, ~] = ginput(1);
    Xs(i) = round(x);
end
%}


%%
clear
% load('D:\Dropbox\Andermann research\Matlab_files\Photometry bhvstructs\MPOA social full.mat')
load('D:\Personal Dropbox\StephenZhangLab\Dropbox\Dropbox Server\Matlab_files\Photometry bhvstructs\MPOA social full.mat')


%% Use sliding-window normalized version
datastruct_social = datastruct_social_n;

%% Add a nan head
%
for i = 1 : 88
    datastruct_social(i).photometry = [nan(500,1); datastruct_social(i).photometry];
    datastruct_social(i).CloseExam = [zeros(500,1); datastruct_social(i).CloseExam];
    datastruct_social(i).Approach = [zeros(500,1); datastruct_social(i).Approach];
end
%}

%% Postprocess photometry data
% Inputs
varargin_pp = {'Fs_ds', 10, 'smooth_window', 0, 'zscore_badframes', 1 : 10,...
    'First_point', 1, 'BlankTime', [], 'nozscore', false,...
    'usedff', false, 'externalsigma', []};
datastruct_social_pp = ppdatastruct(datastruct_social, varargin_pp);


%% Make a sniffing construct
% Input for introm structure
varargin_CloseExamstruct = {'datafield','photometry','bhvfield', 'CloseExam',...
    'norm_length', 10, 'pre_space', 3, 'post_space', 3, 'trim_data', true,...
    'trim_lndata', true, 'premean2s', true, 'removenantrials', false};
CloseExamstruct = mkbhvstruct(datastruct_social_pp, varargin_CloseExamstruct);

varargin_Approach = {'datafield','photometry','bhvfield', 'Approach',...
    'norm_length', 10, 'pre_space', 3, 'post_space',3, 'trim_data', true,...
    'trim_lndata', true, 'boxmean', true, 'removenantrials', false,...
    'nantolerance', 0.2};
Approachstruct = mkbhvstruct(datastruct_social_pp, varargin_Approach);

%% Extract data
%{
[bhvmat, eventlabel] = extbhvstruct(Approachstruct,...
    {'useLN', true, 'pretrim', 3, 'posttrim', 3});
%}
%
[bhvmat, eventlabel] = extbhvstruct(CloseExamstruct,...
    {'useLN', false, 'pretrim', 10, 'posttrim', 10, 'nantolerance', 1});
%}
%% Visualize sniff-trggered data
% showvec = [2 4 5 6 7 8 9 13 15 16 19 20 23 28 31 33 34 35 38 39 40 41 42 56 58 63 64 65 72 73 75 76 77 78 79 80 84 85 86 88];
showvec = [4 6 7 9 13 16 22 23 28 31 34 36 38 39 40 41 56 58 59 63 72 75 76 77 78 80 82  85 86 88];

% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', []},...
    'sortc', 'premean2s', 'sortdir', 'descend', 'heatmaprange', [-3 3],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'showX', showvec};
viewbhvstruct(CloseExamstruct, varargin_viewbhvstruct)

% no z for old sniff data
% z for old boxed sniff data (30 Fs)
%% Visualize approach-locked data
showvec = [2 5 6 7 11 13 17 18 27 28 30 32 36 37 38 40 41 43 44 45 46 53 54 55 56 70 71 72 74 75 78 79 82 84 85 88 ];
% Input
varargin_viewbhvstruct =...
    {'keepc', {'session', []},...
    'sortc', 'boxmean', 'sortdir', 'descend', 'heatmaprange', [-3 3],...
    'datatoplot', {'data_trim', 'ln_data_trim'},...
    'linefields', {'data_trimind', 'ln_data_trimind'}, 'showX', showvec};
viewbhvstruct(Approachstruct, varargin_viewbhvstruct)

% no z for old data