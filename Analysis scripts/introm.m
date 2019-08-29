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
    'First_point', 25, 'BlankTime', 60, 'merging', [0 0 0 1 1]};
datastruct_pp = ppdatastruct(datastruct, varargin_pp);

%% Add a new mount-introm field
% Inputs
varargin_stitch = {'Name', 'MI', 'Event1', 'Mount', 'Event2', 'Introm',...
    'window', 2, 'keepjustEvent1', false, 'keepjustEvent2', true};
datastruct_pp = afdatastruct(datastruct_pp, varargin_stitch);

%% GLM
% A different script
introm_GLM;

%% Make an intromission construct
% Input for introm structure
varargin_introm = {'bhvfield', 'MI', 'norm_length', 10, 'pre_space',...
    20, 'post_space',50, 'trim_data', true, 'trim_lndata', true};
intromstruct = mkbhvstruct(datastruct_pp, varargin_introm);

%% Visualize intromission-trggered data
structkeep = ([intromstruct(:).rorder] <= 12) .* ([intromstruct(:).rorder] > 0);
structkeep = structkeep .* [intromstruct(:).session] == 1;
intromstruct2 = intromstruct(structkeep > 0);

% [~, structorder] = sort([intromstruct2(:).rorder], 'descend');
% intromstruct2 = intromstruct2(structorder);

data2view_ln = [intromstruct2(:).ln_data_trim]';
data2view = [intromstruct2(:).data_trim]';

figure

subplot(6,2,3:2:12);
imagesc(data2view, [-3 3])
xrange = get(gca,'xlim');
xlabel('Time')
set(gca,'YTickLabel',[]);
set(gca,'XTickLabel',[]);
hold on
for i = 1 : length(intromstruct2)
%     plot(intromstruct2(i).ln_data_trimind, [i i], 'r-');
    plot(intromstruct2(i).data_trimind, [i i], 'r-');
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
for i = 1 : length(intromstruct2)
    plot(intromstruct2(i).ln_data_trimind, [i i], 'r-');
    
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