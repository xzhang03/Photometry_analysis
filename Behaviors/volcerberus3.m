chs = [9 10 11];

t1 = chainfinder(data(chs(1),:)>0.5);
t2 = chainfinder(data(chs(2),:)>0.5);
t3 = chainfinder(data(chs(3),:)>0.5);

v1 = zeros(size(data,2), 1);
v2 = zeros(size(data,2), 1);
v3 = zeros(size(data,2), 1);

v1(t1(:,1)) = round(t1(:,2)/20);