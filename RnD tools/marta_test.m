[out, f0] = tcpPercentiledff(Ch1_filtered, freq, 15, 10);

%% Plot
plot(out)
hold on 
plot(opto)
hold off