function datavec_artifactremoved = artifact_interpolate(TrigCfg, data, ch1_data_table)
traingap = 50;
% Number of artifacts
nartifacts = length(TrigCfg.artifact_ch);

for i = 1 : nartifacts
    artifactch = TrigCfg.artifact_ch(i);
    tempartifact = tcpDatasnapper(data(artifactch,:),data(2,:));

    if i == 1
        artifactvecs = tempartifact(:,2);
    else
        artifactvecs(:,i) = tempartifact(:,2);
    end
end

artifactvec = sum(artifactvecs,2);

% Points to remove
pts2remove = chainfinder(abs(artifactvec)>0.1);
pts2remove(:,2) = pts2remove(:,1) + pts2remove(:,2) - 1;

% In train mode
if traingap > 0
    % Get the inter-pulse interval and remove the ones that are shorter
    % than the gap
    trigpulses_keep = diff(pts2remove(:,1)) >= traingap;

    % A vector of the first pulses of each train
    trigpulses_first = [true; trigpulses_keep];

    % A vector of the last pulses of each train
    trigpulses_last = [trigpulses_keep; true];

    % Get the onsets and offsets of each train
    pts2remove = [pts2remove(trigpulses_first, 1), pts2remove(trigpulses_last, 2)];
end

datavec_artifactremoved = ch1_data_table(:,2);

for j = 1 : size(pts2remove,1)
    ini_ind = pts2remove(j,1) - 50;
    end_ind = pts2remove(j,2) + 20;
    datavec_artifactremoved(ini_ind:end_ind) = mean(datavec_artifactremoved([ini_ind - 1, end_ind + 1]));
end
end