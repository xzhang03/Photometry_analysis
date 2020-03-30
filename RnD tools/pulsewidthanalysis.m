data_chan = 1;
pulse_1_chan = 2;
pulse_2_chan = 5;

% Blackout window
blackout = 9;

pulses1 = chainfinder(data(pulse_1_chan,:) > 2.5);
pulses2 = chainfinder(data(pulse_2_chan,:) > 0.5);

% npoints = min(size(pulses1,1), size(pulses2,1));
npoints = 3000;

maxwidth = 23;

sigmat1 = nan(npoints, maxwidth);
sigmat2 = nan(npoints, maxwidth);

for ii = 1 : npoints
    for i = 1 : maxwidth
        % Wavelength 1
        ini_ind = pulses1(ii,1) + blackout;
        end_ind = pulses1(ii,1) + min(pulses1(ii,2), i) - 1;
        sigmat1(ii,i) = median(data(data_chan, ini_ind:end_ind));
        
        % Wavelength 2
        ini_ind = pulses2(ii,1) + blackout;
        end_ind = pulses2(ii,1) + min(pulses2(ii,2), i) - 1;
        sigmat2(ii,i) = median(data(data_chan, ini_ind:end_ind));
    end
end

errorvec1 = nan(maxwidth, 1);
errorvec2 = nan(maxwidth, 1);

for i = 1 : maxwidth
    errorvec1(i) = sqrt(mean((sigmat1(:,i) - sigmat1(:, maxwidth)).^2));
    errorvec2(i) = sqrt(mean((sigmat2(:,i) - sigmat2(:, maxwidth)).^2));
end

plot([errorvec1, errorvec2])
legend({'Ch1 error', 'Ch2 error'})
xlabel('Window size')
ylabel('RMS')