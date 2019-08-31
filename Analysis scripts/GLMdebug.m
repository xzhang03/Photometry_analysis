x = sin(1:0.1:10)';
y = cos(1:0.1:10)';
z = 2 * x + y;

glmfit([x,y],z,'normal', 'Offset');