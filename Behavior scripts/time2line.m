%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\behavior';

%% IO
% Which data files to look at {mouse, date, run}
inputloadingcell = {'SZ365', 200315, 1};

% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell,defaultpath);

% Load behavior things
A = load (fullfile(loadingcell{1,1}, loadingcell{1,3}), 'A');
A = A.A;

% Time limit
xlims = [0 15];
%% Plot parameters
% Row look up table
rowLUT = [  0, 1; 0.5, NaN;...
            1, 2; 2, 2;...
            3, 2; 7, 3;...
            4, 4; 5, 5;...
            6, 6; 8, NaN];

% Color look up table
colorLUT = {0, '808080', 1; 0.5, '808080', 1;...
            1, 'ed2224', 0.35; 2, 'ed2224', 1;...
            3, '000000', 1; 4, '28a8e0', 1;...
            5, '30419a', 1; 6, '009347', 1;...
            7, 'f16521', 1; 8, '722a8f', 1};
        
% Minimal line length
minimallinelength = 0;

% Line width
Linewidth = 9;
%% Make plot

figure(101)
hold on
for i =1 : size(A,1)
    
    % Type
    j = A(i,1);
    
    % Row
    rowind = rowLUT(rowLUT(:,1) == j, 2);
    
    % If plotting
    if ~isnan(rowind)
        
        % Color
        colornum = colorconv(colorLUT{cell2mat(colorLUT(:,1)) == j, 2},...
            colorLUT{cell2mat(colorLUT(:,1)) == j, 3});
        
        % Plot
        plot([A(i,2), A(i,3) + minimallinelength], [rowind, rowind], '-',...
            'LineWidth',Linewidth, 'Color', colornum);
    end
    
end

hold off
xlim(xlims)
ylim([0 7])

xlabel('Time (min)','FontSize',14)

pbaspect([6 1 1])

set(gca,'FontSize',14)
set(gca, 'YTickLabel', {})