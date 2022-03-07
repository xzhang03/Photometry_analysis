%% Setting
maxtime = 10; % In min
minimallinelength = 0.03;
Linewidth = 7; %
colormap = {0, '000000'; 1, 'a0a0a0'; 2, 'ed2224'; 3, '722a8f'};
colorv = cell2mat(colormap(:,1));

%% IO
fpdefault = 'D:\Dropbox\Andermann research\Matlab_files\GiDreadd females';
[fnlist, fp] = uigetfile(fullfile(fpdefault, '*.mat'), 'MultiSelect', 'on');
nfiles = length(fnlist);

%% Process
figure
hold on
for i = 1 : nfiles
    fn = fnlist{i};
    loaded = load(fullfile(fp, fn));
    nbouts = size(loaded.timemat,1);
    
    for j = 1 : nbouts
        btype = loaded.timemat(j, 1);
        if btype >= 0
            bstart = loaded.timemat(j, 2) / 60;
            bend = loaded.timemat(j, 3) / 60 + minimallinelength;
            bcolor = colorconv(colormap{colorv == btype, 2});
            plot([bstart,bend], [i,i], '-',...
                'LineWidth',Linewidth,'Color', bcolor);
        end
    end
end
hold off

xlim([0 maxtime])
ylim([0 nfiles+1])
pos = get(gcf, 'Position');
pos(4) = nfiles * 20;
set(gcf, 'Position', pos);