figure('Color', [1 1 1])
plot((1 : n_points)'/freq/60, signal)

%% Scale of seconds

nsamples = 1;

nmaxbouts = size(A,1);

minimallinelength = 0;

Linewidth = 3;

hold on
for i =1 : nmaxbouts
    
    j = A(i,1);
    k = 0.15;
    
    if A(i,1) == 0

        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', colorconv('808080'));

    elseif A(i,1) == 1
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', (1-(1 - colorconv('ed2224')) * 0.65));
        
    elseif A(i,1) == 0.5
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', (1-(1 - colorconv('ed2224')) * 0.3));

    elseif A(i,1) == 2
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', (1-(1 - colorconv('ed2224')) * 1));

    elseif A(i,1) == 3
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', colorconv('000000'));

    elseif A(i,1) == 4
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', colorconv('808080'));

    elseif A(i,1) == 5
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', colorconv('30419a'));

    elseif A(i,1) == 6
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', colorconv('009344'));

    elseif A(i,1) == 7
        plot([A(i,2),A(i,3)+minimallinelength], [k,k], '-',...
            'LineWidth',Linewidth,'Color', colorconv('f16521'));
    end
    
    
end

hold off

xlim([0 15])
% ylim([4.2 6.8])

xlabel('Time (min)','FontSize',14)
ylabel('Behavioral code','FontSize',14)

pbaspect([6 1 1])

set(gca,'FontSize',14)