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
structkeep = ([bhvstruct(:).rorder] <= 12) .* ([bhvstruct(:).rorder] > 9);
% structkeep = structkeep .* [bhvstruct(:).session] == 3;
bhvstruct2 = bhvstruct(structkeep > 0);

[~, structorder] = sort([bhvstruct2(:).rorder], 'descend');
bhvstruct2 = bhvstruct2(structorder);

data2view_ln = [bhvstruct2(:).ln_data_trim]';
data2view = [bhvstruct2(:).data_trim]';

figure('position',[200 350 600 300])

subplot(6,2,3:2:12);
imagesc(data2view, [-3 3])
xrange = get(gca,'xlim');
xlabel('Time')
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
hold on
for i = 1 : length(bhvstruct2)

    plot(bhvstruct2(i).data_trimind, [i i], 'r-');
end
hold off

subplot(6,2,1)
plot(mean(data2view,1));
hold on
plot(xrange, [0 0], 'Color', [0 0 0]);
xlim(xrange);
ylim([min(mean(data2view,1)), max(mean(data2view,1))]);
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
hold off

subplot(6,2,4:2:12);
imagesc(data2view_ln, [-3 3])
xrange = get(gca,'xlim');
xlabel('Time (warped)')
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
hold on
for i = 1 : length(bhvstruct2)
    plot(bhvstruct2(i).ln_data_trimind, [i i], 'r-');
    
end
hold off

subplot(6,2,2)
plot(mean(data2view_ln,1));
hold on
plot(xrange, [0 0], 'Color', [0 0 0]);
xlim(xrange);
ylim([min(mean(data2view_ln,1)), max(mean(data2view_ln,1))]);
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
hold off