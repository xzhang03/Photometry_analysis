function lr = lickrate(lickvec, fs, sliding_win)
if nargin < 3
    sliding_win = 10;
end

lr = movsum(lickvec, sliding_win);
lr = lr / fs;
end