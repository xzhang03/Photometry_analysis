function [newspeed, newpos] = resamplepos(position, campulses, ch_table)
% Resample running to get the sample data rate as photometry

% Camera
cam_table = chainfinder(campulses > 0.5);
camvec = zeros(size(campulses));
for i = 1 : size(cam_table,1)
    camvec(cam_table(i,1)) = 1;
end
camvec = cumsum(camvec);

% Get positions
npoints = size(ch_table, 1);
for i = 1 : npoints
    iend = ch_table(i,1) + ch_table(i,3) - 1;
    ix = camvec(iend);
    if i == 1 && ix == 0
        ix = 1;
    end
    ch_table(i,2) = position(ix);
end

% Calculate
newpos = ch_table(:,2);
newspeed = [0; diff(newpos)];

end