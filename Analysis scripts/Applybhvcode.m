mouse = 'SZ625';
date = '210122';
defaultpath = sprintf('\\\\anastasia\\data\\photometry\\%s\\%s_%s', mouse, date, mouse);


A = exceltime('Defaultt0', '0:00', 'DefaultCode', '0.5');
time2mat(A,defaultpath);