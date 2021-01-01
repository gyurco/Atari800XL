function res = sig_sigmoid(x)
%Another option - SID-sigmoid...
%Ref:Efficient digital implementation of the sigmoid
%function for reprogrammable logic
%M.T. Tommiska

%337p
%358p
x = min(x,8);
x = max(x,-8);
sgn = sign(x);
x = x.*sgn;

x = floor(x*32)/32;

sigmoidreal = @(x) 1./(1.+e.^-x);
y = sigmoidreal(x);
y = floor(y*256)/256;

res = y;
res(sgn<0) = 1-res(sgn<0);

end