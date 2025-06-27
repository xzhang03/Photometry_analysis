fs = [1.19 2.38 3.57 4.76 5.95 7.14 8.33 9.52];


v2 = v(:);
v3 = v2 - mean(v2);
for i = 1 : length(fs)
    d_notch = designfilt('bandstopiir','FilterOrder',2, 'HalfPowerFrequency1',...
            fs(i)-0.1, 'HalfPowerFrequency2',fs(i)+0.1, 'DesignMethod','butter','SampleRate', 25);
    v3 = filter(d_notch, v3);
end
v3 = v3 + mean(v2);



plot([v2 v3])

v4 = reshape(v3, size(v));

trigmat2 = trigmat;
trigmat2(270:290,:) = v4;
