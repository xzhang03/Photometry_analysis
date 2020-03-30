    
channel2look = 4;

pulseind = find(diff(data(4,:))>1);
times = timestamps(pulseind);

pulserate = 1 / ((times(end) - times(2)) / (length(times)-2))   