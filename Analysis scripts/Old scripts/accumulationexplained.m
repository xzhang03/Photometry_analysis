signal = ch1_fixed_filtered - ch2_fixed_filtered + 4;
expfit = fit([10:length(signal)]',signal(10:end), 'exp1');
signal = signal - expfit(1:length(signal));

%%
mu = nanmean(signal);
lambda = nanstd(signal);
signalz = (signal - mu) / lambda;

% attach a nan tail
signalz_t = [signalz; nan(500, 1)];
%%
first_intro = find(B(:,1) == 2,1,'first');
first_intro = round(B(first_intro,2)  * 60 * freq);

fluo_first_intro = mean(signalz(first_intro : (first_intro + freq - 1)));

first_mating = B(:,1) == 3;
first_mating = round(B(first_mating,2)  * 60 * freq);
%%
%
figure
plot(signalz(50:end));
hold on
plot(first_intro, 1.2,  'o',first_mating, 1.2, 'o')
%}

%%
peak_window_sz = 40;
peak_window = signalz((first_mating - peak_window_sz * freq) : (first_mating + peak_window_sz * freq - 1));
peak_window = mean(reshape(peak_window, freq, []));
peak_val = max(peak_window);


%%
deflation_window_sz = 300;
deflation_window = signalz(first_mating +1  : (first_mating + deflation_window_sz * freq));
deflation_window = mean(reshape(deflation_window, freq, []));
deflation_val = median(deflation_window);

%
accumulation2explaine = peak_val - fluo_first_intro
deflation_amp = peak_val - deflation_val
