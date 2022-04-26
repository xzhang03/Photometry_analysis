function signal_mat_out = artifact_glm(signal_mat, data, channels, blackout_window)
% Use GLM to remove artifact
% artifact_glm(signal_mat, data, channels, backoutwindow)

% Basics
n_points = size(signal_mat, 1);
n_channels = length(channels);

% Initialize
X = zeros(n_points, n_channels);
glm_data_mat = signal_mat;

%% Basis function
for ii = 1 : n_channels
    for i = 1 : n_points
        % Use median fluorescence during each pulse to calculate fluorescence
        % values
        % Wavelength 1
        ini_ind = glm_data_mat(i,1) + blackout_window;
        end_ind = glm_data_mat(i,1) + glm_data_mat(i,3) - 1;
        glm_data_mat(i,2) = median(data(channels(ii), ini_ind:end_ind));
    end
    
    % Put in X
    X(:,ii) = glm_data_mat(:,2);
end

%% GLM
b = glmfit(X, signal_mat(:,2), 'normal');

%% Regression
signal_mat_out = signal_mat;
signal_mat_out(:,2) = signal_mat(:,2) - X * b(2:end);

%% Plot 
plotornot = false;
if plotornot
    plot(signal_mat(:,2) - mean(signal_mat(:,2)));
    hold on
    plot(signal_mat_out(:,2) - mean(signal_mat_out(:,2)));
    hold off
end

end