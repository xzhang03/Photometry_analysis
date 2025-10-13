function datastruct = TiffTrimSigStruct(datastruct, window, preframes_override)
if nargin < 3
    preframes_override = [];
end

ncells = length(datastruct);
for icell = 1 : ncells
    % Preframes
    if isempty(preframes_override)
        datastruct(icell).preframes = datastruct(icell).preframes - (window(1)-1);
    else
        datastruct(icell).preframes = preframes_override;
    end
    
    % Trace mat
    datastruct(icell).tracemat = datastruct(icell).tracemat(window(1):window(2), :);
    baseline = mean(datastruct(icell).tracemat(1:datastruct(icell).preframes, :));
    if icell == 1
        l = size(datastruct(icell).tracemat, 1);
    end
    datastruct(icell).tracemat = datastruct(icell).tracemat - ones(l,1) * baseline;
    datastruct(icell).tracevec = mean(datastruct(icell).tracemat, 2);

    % behavioral mats
    datastruct(icell).xymat = datastruct(icell).xymat(window(1):window(2), :);
    datastruct(icell).xyvec = mean(datastruct(icell).xymat, 2);
    datastruct(icell).speedmat = datastruct(icell).speedmat(window(1):window(2), :);
    datastruct(icell).speedvec = mean(datastruct(icell).speedmat, 2);
    if ~isempty(datastruct(icell).lickmat)
        datastruct(icell).lickmat = datastruct(icell).lickmat(window(1):window(2), :);
        datastruct(icell).lickvec = mean(datastruct(icell).lickmat, 2);
    end
    if ~isempty(datastruct(icell).ensuremat)
        datastruct(icell).ensuremat = datastruct(icell).ensuremat(window(1):window(2), :);
        datastruct(icell).ensurevec = mean(datastruct(icell).ensuremat, 2);
    end


end

end