%% Initialize
clear

% Default path
defaultpath = '\\anastasia\data\behavior';

%% Plot parameters

% Color look up table
colorLUT = {0, '808080', 1; 0.5, '808080', 1;...
            1, 'ed2224', 1; 2, 'ed2224', 1;...
            3, '000000', 1; 4, '28a8e0', 1;...
            5, '30419a', 1; 6, '009347', 1;...
            7, 'f16521', 1; 8, '722a8f', 1};
        
% Minimal line length
minimallinelength = 0;

% Line width
Linewidth = 9;

% Time limit
xlims = [0 15];

% Y limit for scaling
ylims = [0 6];
%% IO (overall)
% Which data files to look at {mouse, date, run}
inputloadingcell_nai = {'SZ07', 190119, 1; 'SZ28', 190208, 1; 'SZ29', 190208, 1; ...
    'SZ119', 190613, 1; 'SZ120', 190613, 1};

inputloadingcell_0 = {'SZ05', 181225, 2; 'SZ05', 181225, 3; 'SZ04', 190131, 2;...
    'SZ06', 190106, 2; 'SZ07', 190119, 2};

inputloadingcell_1 = {'SZ119', 190614, 1; 'SZ120', 190614, 1; 'SZ122', 190615, 1;...
    'SZ121', 190616, 1; 'SZ123', 190616, 1; 'SZ126', 190617, 1}; 

inputloadingcell_3 = {'SZ119', 190616, 1; 'SZ120', 190616, 1; 'SZ124', 190616, 1;...
    'SZ121', 190619, 1; 'SZ123', 190619, 1}; 

inputloadingcell_5 = {'SZ119', 190618, 1; 'SZ120', 190618, 1; 'SZ124', 190618, 1;...
    'SZ122', 190619, 1; 'SZ121', 190620, 1};

inputloadingcell_7 = {'SZ119', 190620, 1; 'SZ120', 190620, 1; 'SZ124', 190620, 1;...
    'SZ121', 190704, 1; 'SZ123', 190704, 1};

inputloadingcell_9 = {'SZ122', 190623, 1; 'SZ121', 190624, 1; 'SZ123', 190624, 1;...
    'SZ126', 190702, 1; 'SZ119', 190624, 1};
%% Subset
Day = 9;

switch Day
    case -1
        inputloadingcell = inputloadingcell_nai;
    case 0
        inputloadingcell = inputloadingcell_0;
    case 1
        inputloadingcell = inputloadingcell_1;
    case 3
        inputloadingcell = inputloadingcell_3;
    case 5
        inputloadingcell = inputloadingcell_5;
    case 7
        inputloadingcell = inputloadingcell_7;
    case 9
        inputloadingcell = inputloadingcell_9;
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