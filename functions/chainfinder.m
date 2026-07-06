function [ chainmat ] = chainfinder( inputvec )
%chainfinder reports the chains of consecutive numbers
%   Input:
%   inputvec: a vector of data to find chains within
%
%   Output:
%   chainmat: a n-by-2 matrix to report the chains found. Each row is a
%             chain. The first column tells where each chain starts. The
%             second column tells the lengths of the chains.

inputvec = inputvec(:);
n_num = length(inputvec);

if n_num == 0
    chainmat = [];
    return
end

% A run boundary occurs wherever the value changes from the previous entry
changePts = find(diff(inputvec) ~= 0);
runStarts = [1; changePts + 1];
runEnds = [changePts; n_num];
runLengths = runEnds - runStarts + 1;
runValues = inputvec(runStarts);

% Keep only the runs of (consecutive, identical) nonzero values
keep = runValues ~= 0;
chainmat = [runStarts(keep), runLengths(keep)];

if isempty(chainmat)
    chainmat = [];
end

end
