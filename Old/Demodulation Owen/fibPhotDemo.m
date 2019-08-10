% This script demonstrates importing photometry data from a .edr file and
% procesing using zero lag filters to isolate the time-varying
% fluoroescence signal.

% Instructions
% 1) Set min and max values for params.freqRange1 and params.freqRange2 so
%    each range spans the target oscillation frequency of that channel, and
%    (ideally) excludes the oscillation on the opposite channel
% 2) Start the script
% 3) Most useful output variables are:
%    dsTimes             -- the time stamps of the output data
%    rawVals1 & rawVals2 -- output data before photobleaching correction
%    dsVals1 & dsVals2   -- photobleaching corrected data for channels 1 and 2
%    syncInTimes         -- timestamps of TTL events on SyncIn channel
%    syncOutTimes        -- timestamps of TTL events on SyncOut channel


% Scott Owen -- 2018-08-11

% SET THESE VALUES TO SPAN THE FREQUENCIES USED DURING RECORDING
params.freqStep   = 5; % Step sfize in Hz for freqency calculations
params.freqRange1 = [200 230]; % Min and max frequency range for channel 1 (target 217 Hz)
params.freqRange2 = [300 330]; % Min and max frequency range for channel 2 (target 319 Hz)

% Select the raw data file to be read
% [fname,fdir] = uigetfile('*.edr'); % or type filename in here as a string using '####';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    IDEALLY NOTHING BELOW THIS POINT NEEDS TO BE CHANGED BY THE USER     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% disp(['Reading ', fdir, fname]);

% Assign the channel numbers in the raw data set
% params.timeCol    = 1;
params.rawSigCol1 = 1; % Where do you get raw data for Channel 1
params.rawSigCol2 = 1; % Where do you get raw data for Channel 1
% params.syncColIn  = 8;
% params.syncColOut = 9;

params.winSize = 0.04; % Targe window size (in sec) for FFT frequency calc
params.spectSample = 0.01; % Step size for spectrogram (sec)
params.inclFreqWin = 1; % Number of frequency bins to average (on either side of peak freq)
params.filtCut = 10; % Cut off frequency for low pass filter of processed data
params.filtCutOsc = 400; % Cut-off frequency for low-pass filter of oscillation data.
params.dsRate = 0.05; % Time steps for donw-sampling

rawData = data';

% Apply notch filter to remove 60 Hz noise
d_notch = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1',...
    59, 'HalfPowerFrequency2',61, 'DesignMethod','butter','SampleRate', Fs);
rawData(:,1) = filter(d_notch, rawData(:,1));
%%
% Read in raw photometry data from EDR file
% [rawData,edrHead] = import_edr([fdir,fname]);

% Find syncing TTL pulses
% [upLocs, downLocs] = findTTLpulses(rawData(:,params.syncColIn));
% if ~isempty(upLocs)
%     syncInTimes = rawData(upLocs,params.timeCol);
% else
%     syncInTimes = [];
% end
% [upLocs, downLocs] = findTTLpulses(rawData(:,params.syncColOut));
% if ~isempty(upLocs)
%     syncOutTimes = rawData(upLocs,params.timeCol);
% else
%     syncOutTimes = [];
% end

% Calculate spectrogram channel 1
useFreqRange = params.freqRange1(1):params.freqStep:params.freqRange1(2);
[filtTimes,filtSig1, rawSig1, spectFreqs1, spectAmpVals1] = ...
    sfoReadFibPhot(rawData(:,params.rawSigCol1), ... % raw data
    Fs, ... % Sampling frequency
    useFreqRange, ... % Frequency range to search for peaks
    params);

% Calculate spectrogram channel 2
useFreqRange = params.freqRange2(1):params.freqStep:params.freqRange2(2);
[filtTimes,filtSig2, rawSig2, spectFreqs2, spectAmpVals2] = ...
    sfoReadFibPhot(rawData(:,params.rawSigCol2), ... % raw data
    Fs, ... % Sampling frequency
    useFreqRange, ... % Frequency range to search for peaks
    params);

% Determine time points in output data set
dsTimes = filtTimes(1):params.dsRate:filtTimes(end); 

% % Design a filter kernel
% d = fdesign.lowpass('Fp,Fst,Ap,Ast',8,10,0.5,40,100);
% Hd = design(d,'equiripple');
% 
% Ch1_filtered = filter(Hd,filtSig1);
% Ch2_filtered = filter(Hd,filtSig2);
%%
figure(101)
subplot(1,2,1)
plot([filtSig1' - (filtSig1(1) - filtSig2(1)),filtSig2'])
xlabel('Sample')
ylabel('Demodulated signal')
title('Frequency based demodulation')
subplot(1,2,2)
[p1,f] = ft2(filtSig1, 1/(filtTimes(2) - filtTimes(1)));
[p2,~] = ft2(filtSig2, 1/(filtTimes(2) - filtTimes(1)));
figure(101)
plot(f(2:end), [p1(2:end),p2(2:end)]);
title('FT')
xlabel('Freq (Hz)');
ylabel('Power');
%%

% Fit each channel to exponential decay for photobleaching correction
pbFit1 = fit(filtTimes',filtSig1','exp1'); 
pbFit2 = fit(filtTimes',filtSig2','exp1');

% Divide filtered signal by exponential decay to correct for photobleaching
pbVals1 = (filtSig1' ./ double(pbFit1(filtTimes)))';
pbVals2 = (filtSig2' ./ double(pbFit2(filtTimes)))';

% Downsample photobleaching-corrected data
dsVals1 = interp1(filtTimes,pbVals1,dsTimes,'spline');
dsVals2 = interp1(filtTimes,pbVals2,dsTimes,'spline');

% Downsample raw (uncorrected) data
rawVals1 = interp1(filtTimes,filtSig1',dsTimes,'spline');
rawVals2 = interp1(filtTimes,filtSig2',dsTimes,'spline');