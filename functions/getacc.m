function [slopes, coefcorr, LMF] = getacc(Mat, Fs, DIM)
% getacc will give a vector of the slopes using the data. NaNs are
% removed. Dimension can be specified (default along each column). It also
% gives coefficient of correlation. It also gives last-minus-first-bin
% values. Bin size is defined as sampling rate.
% [slopes, coefcorr, LMF] = getacc(Mat, Fs, DIM)

if nargin < 3
    DIM = 1;
    if nargin < 2
        Fs = 50;
    end
end

% Reorient matrix if needed
if DIM == 2
    Mat = Mat';
end

% Initialize ouputs
slopes = nan(size(Mat,2), 1);
coefcorr = nan(size(Mat,2), 1);
LMF = nan(size(Mat,2), 1);

% Loop through
for i = 1 : size(Mat,2)
    % Grab data and remove NaNs
    data_line = Mat(:,i);
    data_line = data_line(~isnan(data_line));
    
    % fit
    fitinfo = polyfit((1:length(data_line))'/Fs, data_line, 1);
    
    % Get slopes
    slopes(i) = fitinfo(1);

    % Get cc
    tempcc = corrcoef((1:length(data_line))/Fs, data_line');
    coefcorr(i) = tempcc(2,1);
    
    % Get LMF
    LMF(i) = mean(data_line(end - Fs + 1: end)) - mean(data_line(1: Fs));
    
end

end