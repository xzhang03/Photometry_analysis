%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\photometry';

% Which data files to look at {mouse, date, run}
inputloadingcell_MPOAcaddisExpt = {'SZ226', 191111, 1; 'SZ226', 191112, 1;...
    'SZ226', 191114, 1; 'SZ228', 191111, 1; 'SZ228', 191112, 1; 'SZ228', 191114, 1;...
    'SZ242', 191111, 1; 'SZ242', 191112, 1; 'SZ242', 191114, 1; 'SZ244', 191111, 1;...
    'SZ244', 191112, 1; 'SZ244', 191114, 1; 'SZ226', 191115, 1; 'SZ228', 191115, 1;...
    'SZ242', 191115, 1; 'SZ244', 191115, 1; 'SZ226', 191119, 1; 'SZ226', 191120, 1;...
    'SZ228', 191120, 1; 'SZ242', 191120, 1; 'SZ243', 191119, 1; 'SZ243', 191120, 1;...
    'SZ244', 191120, 1; 'SZ245', 191119, 1; 'SZ245', 191120, 1; 'SZ246', 191119, 1;...
    'SZ246', 191120, 1; 'SZ226', 191122, 1; 'SZ228', 191122, 1; 'SZ242', 191122, 1;...
    'SZ244', 191122, 1; 'SZ226', 191122, 1; 'SZ228', 191126, 1; 'SZ242', 191126, 1;...
    'SZ243', 191125, 1; 'SZ244', 191126, 1; 'SZ245', 191125, 1; 'SZ246', 191125, 1;}; 
tcpCheck(inputloadingcell_MPOAcaddisExpt, 'twocolor', false, 'headfixed', true);

% Which data files to look at {mouse, date, run}
inputloadingcell_MPOAcaddisCont = {'SZ194', 191009, 1; 'SZ194', 191011, 1;...
    'SZ194', 191017, 1; 'SZ194', 191018, 1; 'SZ194', 191021, 1; 'SZ194', 191022, 1;...
    'SZ194', 191023, 1; 'SZ194', 191024, 1; 'SZ194', 191025, 1; ...
    'SZ194', 191029, 1; 'SZ194', 191030, 1; }; 
tcpCheck(inputloadingcell_MPOAcaddisCont, 'twocolor', false, 'headfixed', true);

% Which dta files to look at {mouse, date, run}
inputloadingcell_MPOAcaddisSCH = {'SZ226', 191215, 1; 'SZ226', 191216, 1;...
    'SZ242', 191215, 1; 'SZ242', 191216, 1; 'SZ243', 191215, 1; 'SZ243', 191216, 1;...
    'SZ244', 191215, 1; 'SZ244', 191216, 1; 'SZ245', 191215, 1; 'SZ245', 191216, 1;...
    'SZ246', 191215, 1; 'SZ246', 191216, 1;};
tcpCheck(inputloadingcell_MPOAcaddisSCH, 'twocolor', false, 'headfixed', true);

%% Check fits
% index
% ind = 16, 18, 19;
ind = 21;

% Loading cell
if ~exist('loadingcell', 'var')
    loadingcell = mkloadingcell(inputloadingcell_MPOAcaddisExpt, defaultpath);
end

% Load
loaded = load(fullfile(loadingcell{ind,1}, loadingcell{ind,6}));

% Stims
nstims = length(loaded.opto_ons);
stimpt = loaded.opto_ons(1);
stimvec = zeros(length(loaded.exp_fit),1);
for i = 1 : min(nstims, 40)
    stimvec(stimpt:stimpt+200) = 1;
    stimpt = stimpt + 1500;
end

% Plot
% data2plot = [(1:length(loaded.exp_fit))'/loaded.freq/60,...
%     loaded.data2use+loaded.exp_fit, loaded.exp_fit,stimvec];
% data2plot = downsample(data2plot,50);
% plot(data2plot(40:end,1),data2plot(40:end,2:end));

loaded.Z
f = fit(data2plot(3:300,1),data2plot(3:300,2),'exp1');
plot(f,data2plot(:,1),data2plot(:,2))
%% Fix stuff
%{
tcpFixTrigger(inputloadingcell_MPOAcaddisCont, 'defaultpath', defaultpath,...
    'flatten_unfiltered', true, 'add_opto', true, 'checkfield', '', 'reduce_opto', true);
%}

%% Get Zs
%{
tcpZ([inputloadingcell_MPOAcaddisExpt; inputloadingcell_MPOAcaddisCont;...
    inputloadingcell_MPOAcaddisSCH], 'defaultpath', defaultpath);
%}
%% Low-pass filter
% Get a better filter
d = fdesign.lowpass('Fp,Fst,Ap,Ast',7,9,0.5,40, 50);
Hd = design(d,'equiripple');

%% Make experimental data struct
% Experimental group
[datastruct_MPOAcaddisExpt, n_series_MPOAcaddisExpt] =...
    mkoptostruct(inputloadingcell_MPOAcaddisExpt, 'defaultpath', defaultpath,...
    'externalsigma', 0.04, 'zero_baseline', true, 'zero_baseline_per_session', true,...
    'linearleveling', true, 'useunfiltered', true, 'refilter', Hd, 'checkoptopulses', false,...
    'pretrigwindow', [-240 -180], 'posttrigwindow', [300 420], 'useinternalsigma', true);
% 0.04

%% Made control data struct
% Control group
[datastruct_MPOAcaddisCont, n_series_MPOAcaddisCont] =...
    mkoptostruct(inputloadingcell_MPOAcaddisCont, 'defaultpath', defaultpath,...
    'externalsigma', 0.15, 'zero_baseline', true, 'zero_baseline_per_session', true,...
    'badtrials', [11 1], 'linearleveling', false, 'useunfiltered', true, 'refilter', Hd,...
    'pretrigwindow', [-240 -180], 'shuffledata', false);
% 0.15

%% Make SCH23390 data struct
% D1 D5 antagonist
[datastruct_MPOAcaddisSCH, n_series_MPOAcaddisSCH] =...
    mkoptostruct(inputloadingcell_MPOAcaddisSCH, 'defaultpath', defaultpath,...
    'externalsigma', 0.06, 'zero_baseline', true, 'zero_baseline_per_session', true,...
    'badtrials', [6 7; 6 8], 'linearleveling', false, 'useunfiltered', true,...
    'refilter', Hd, 'checkoptopulses', false, 'pretrigwindow', [-240 -180],...
    'useinternalsigma', true);
% 0.06
%% View data struct experimental
sets = [1 3 4 7 8 9 11 12 13 14 15 16 18 19 20 21 22 23 24 25 26 28 29 31 32 33 34 35 36 37 38];
% sets = [1 7 8 9 11 13 14 15 16 18 19 20 23 25 26 28 31 32 33 35];

varargin_viewopto = {'datasets', sets, 'flip_signal', true, 'yrange', [],...
    'heatmaprange', [-1 1], 'showX', [], 'optolength', 248, 'usemedian', false,...
    'keepc', {'order', []}, 'outputdata', true, 'outputfs', 50, 'datatype', 'trig'};
viewoptostruct(datastruct_MPOAcaddisExpt, varargin_viewopto);

%% View data struct control
% 7 8 9 10 11
varargin_viewopto = {'datasets', [7 8 9 10 11], 'flip_signal', true, 'yrange', [],...
    'heatmaprange', [-1 1], 'showX', [], 'optolength', 248, 'usemedian', false,...
    'keepc', {'order', []}, 'outputdata', true, 'outputfs', 10,...
    'datatype', 'trig'};
viewoptostruct(datastruct_MPOAcaddisCont, varargin_viewopto);


%% View data struct SCH23390
varargin_viewopto = {'datasets', [], 'flip_signal', true, 'yrange', [],...
    'heatmaprange', [-1 1], 'showX', [], 'optolength', 248, 'usemedian', false,...
    'keepc', {'order', []}, 'outputdata', true, 'outputfs', 50,...
    'datatype', 'trig'};
viewoptostruct(datastruct_MPOAcaddisSCH, varargin_viewopto);


