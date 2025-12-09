function speed = runningspeed(speedvec, fs, sliding_win)
if nargin < 3
    sliding_win = 10;
end

wheeldiameter = 14;
wheelteeth = 22;
speed = speedvec / 4 * wheeldiameter * pi / wheelteeth; % I think the encoder outputs a 4 after each beam break
speed = movsum(speed, sliding_win)/fs;

end