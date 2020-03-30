%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\behavior';

%% Plot parameters

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

% Time limit
xlims = [0 5];

% Y limit for scaling
ylims = [0 7];
%% IO (overall)
% Which data files to look at {mouse, date, run}
inputloadingcell_1 = {'SZ313', 200218, 1; 'SZ314', 200218, 1; 'SZ315', 200218, 1; ...
    'SZ316', 200220, 1; 'SZ320', 200220, 1; 'SZ321', 200220, 1; 'SZ322', 200220, 1;...
    'SZ323', 200220, 1; 'SZ315', 200223, 1};

inputloadingcell_3 = {'SZ313', 200220, 1; 'SZ314', 200220, 1; 'SZ315', 200220, 1; ...
    'SZ316', 200222, 1; 'SZ320', 200222, 1; 'SZ321', 200222, 1; 'SZ322', 200222, 1;...
    'SZ323', 200222, 1; 'SZ315', 200225, 1};

inputloadingcell_5 = {'SZ313', 200222, 1; 'SZ314', 200222, 1; 'SZ315', 200222, 1; ...
    'SZ316', 200224, 1; 'SZ320', 200224, 1; 'SZ321', 200224, 1; 'SZ322', 200224, 1;...
    'SZ323', 200224, 1; 'SZ315', 200227, 1};

%% Genotypes
RNAi = {'SZ313', 'SZ315', 'SZ321', 'SZ323'};
Ctrl = {'SZ314', 'SZ316', 'SZ320', 'SZ322'};

%% Subset
Day = 1;
Geno = 'Ctrl';

if Day == 1
    inputloadingcell = inputloadingcell_1;
elseif Day == 3
    inputloadingcell = inputloadingcell_3;
elseif Day == 5
    inputloadingcell = inputloadingcell_5;
end

if strcmpi(Geno, 'RNAi')
    inputloadingcell = inputloadingcell(ismember(inputloadingcell(:,1), RNAi), :);
elseif strcmpi(Geno, 'Ctrl')
    inputloadingcell = inputloadingcell(ismember(inputloadingcell(:,1), Ctrl), :);
end

%% Loading cell
% Make actual loading cell
loadingcell = mkloadingcell(inputloadingcell,defaultpath);
ndatasets = size(loadingcell, 1);


%% Make plot

figure(101)
hold on

for ii = 1 : ndatasets
    
    % Load behavior things
    A = load (fullfile(loadingcell{ii,1}, loadingcell{ii,3}), 'A');
    A = A.A;
    
    for i = 1 : size(A,1)
        % Type
        j = A(i,1);

        % Row
        rowind = ii;

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
ylim(ylims)

xlabel('Time (min)','FontSize',14)

pbaspect([6 1 1])

set(gca,'FontSize',14)
set(gca, 'YTickLabel', {})