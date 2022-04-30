%% Grab data points
lick_data_table = ch1_data_table;
blackout_window = 9;



%%
plot(ch1_data_table(:,2))
hold on
plot(lick_data_table(:,2))
hold off

test1 = ch1_data_table(:,2);
test2 = lick_data_table(:,2);

%%
b = glmfit(test2, test1, 'normal');

plot(test1)
hold on
plot(test1 - test2 * b(2))
hold off