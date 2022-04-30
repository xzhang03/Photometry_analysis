testspeed = speed_upsampled;
gauss_distribution = @(x, mu, s) exp(-.5 * ((x - mu)/s) .^ 2) ./ (s * sqrt(2*pi)); 
gs = gauss_distribution(-200:200,0,500)';
testspeed = conv(testspeed, gs, 'same');

% Initialize a triggered speed matrix
speedmat = zeros(l, n_optostims);
for i = 1 : n_optostims
    speedmat(:,i) = testspeed(inds(i,1) : inds(i,2));
end

ws = glmfit(speedmat(:)', trigmat(:)', 'normal');

figure
trigmat2 = trigmat - speedmat * 0.002;
hold on
plot(mat2gray(mean(trigmat(:,:),2)))
plot(mat2gray(mean(trigmat2(:,:),2)))
hold off
title(num2str(ws(2)))

%%
ws = glmfit(testspeed, data2use, 'normal');
trigmat2 = trigmat - speedmat * ws(2);
figure
hold on
plot(mat2gray(mean(trigmat(:,:),2)))
plot(mat2gray(mean(trigmat2(:,:),2)))
hold off
title(num2str(ws(2)))

%%
lickmat = ch1_data_table;
for i = 1 : n_points
    % Wavelength 1
    ini_ind = lickmat(i,1) + 6;
    end_ind = lickmat(i,1) + lickmat(i,3) - 1;
    lickmat(i,2) = median(data(6, ini_ind:end_ind));
end
lickvec = lickmat(:,2);

lickmat2 = zeros(l, n_optostims);
for i = 1 : n_optostims
    lickmat2(:,i) = lickvec(inds(i,1) : inds(i,2));
end
%%
figure
hold on
plot(mean(lickmat2(:,2),2));
plot(mean(speedmat(:,2),2));
hold off
%%
v1 = lickmat2(:);
v2 = speedmat(:);

v1 = tcpBin(v1, 10, 1);
v1 = v1 - mean(v1);
v1 = smooth(v1, 100);
v2 = tcpBin(v2, 10, 1);
v2 = v2 - mean(v2);
v2 = smooth(v2, 100);
figure
subplot(1,2,1)
hold on
plot(v1)
plot(v2)
hold off

subplot(1,2,2)
[C, lags] = xcorr(v1,v2);
plot(lags, C);

%%
v1 = zeros(10,1);
v1([1 4 10]) = 1;
v1c = conv(v1, [1 1 1], 'same')
