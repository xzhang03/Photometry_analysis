Ch1_on = chainfinder(ch1_pulse);
Ch1_off = chainfinder(ch1_pulse == 0);

Ch2_on = chainfinder(ch2_pulse);
Ch2_off = chainfinder(ch2_pulse == 0);

disp(['Channel 1 pulses on at ', num2str(mean(Ch1_on(:,2))),...
    ' +/- ', num2str(std(Ch1_on(:,2)))])

disp(['Channel 1 pulses off at ', num2str(mean(Ch1_off(:,2))),...
    ' +/- ', num2str(std(Ch1_off(:,2)))])

disp(['Channel 2 pulses on at ', num2str(mean(Ch2_on(:,2))),...
    ' +/- ', num2str(std(Ch2_on(:,2)))])

disp(['Channel 2 pulses off at ', num2str(mean(Ch2_off(:,2))),...
    ' +/- ', num2str(std(Ch2_off(:,2)))])