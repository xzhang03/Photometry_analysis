function [spectTimes, filtSig, sig, spectFreqs, spectAmpVals] = ...
    sfoReadFibPhot(rawData, fs, freqRange, params)

% Reads in:
% 1) rawData -- the raw oscillating photometry signal
% 2) fs -- sampling frequency
% 3) freqRange -- 2 element array of frequency ranges to be analyzed
% 4) params -- structure with following elements (and default values used):

% Scott Owen -- 2019-04-04
% This version corrects an error in the cut-off frequency of the low-pass
% filtering for the output data

% Convert spectrogram window size and overlap from time to samples
spectWindow = 2.^nextpow2(fs .* params.winSize);
spectOverlap = ceil(spectWindow - (spectWindow .* (params.spectSample ./ params.winSize)));
disp(['Spectrum window ', num2str(spectWindow ./ fs), ' sec; ',...
    num2str(spectWindow), ' samples at ', num2str(fs), ' Hz'])

% Calculate spectrogram
[spectVals,spectFreqs,spectTimes]=spectrogram(rawData,spectWindow,spectOverlap,freqRange,fs);
% Convert spectrogram to real units
spectAmpVals = double(abs(spectVals)); 
% Find the two carrier frequencies
avgFreqAmps = mean(spectAmpVals,2);
[pks,locs]=findpeaks(double(avgFreqAmps));
if max(pks) == 1 && length(pks) > 1
    pks(1) = []; locs(1) = [];
end
[maxVal,maxFreqBin] = max(pks);
maxFreqBin = locs(maxFreqBin);

% Calculate signal at each frequency band
sig = mean(abs(spectVals((maxFreqBin-params.inclFreqWin):(maxFreqBin+params.inclFreqWin),:)),1);

% Low pass filter the signals
if params.filtCut <= 1 ./ (2 .* mean(diff(spectTimes)))
    lpFilt = designfilt('lowpassiir','FilterOrder',8, 'PassbandFrequency',params.filtCut,...
        'PassbandRipple',0.01, 'SampleRate',1./mean(diff(spectTimes)));
    filtSig = filtfilt(lpFilt,double(sig));
else
    % If filter cut-off is too low for given sampling rate, then skip the filtering
    filtSig = double(sig);
end
