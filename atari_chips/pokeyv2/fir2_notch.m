pkg load signal;

fsample = 48000;
%fsample = 24000;

%notches = [15600/4,15600/2,15600];
cutoff = [15600,15600];
cutoff_norm = cutoff/(fsample/2);
%notches = load('notches');
%notches = notches.freqs;
notches = []
linepal = 312*49.86;
linentsc = 262*59.92;
for i=1:8
  notches(end+1) = i*linepal/8;
  notches(end+1) = i*linentsc/8;
end
notches(end+1) = linepal/64;
notches(end+1) = linentsc/64;
notches = notches(notches<cutoff(2));
notches_norm = notches/(fsample/2);

steps = 10000;

l=0;
%thr = 0.0008;
thr = 0.0016;
%thr = 0.0032;
for i = 0.0:1.0/steps:1.0
  l=l+1;
  pos(l) = i;
  val = min(((i-notches_norm).^2).^0.5);
  if val>thr
    func(l)=  1.0;
  else
    func(l) = 0.0;
  endif
  if i>cutoff_norm(2)
    func(l) = 0;
    continue;
  endif
  if i>cutoff_norm(1)
    cutoff_normd = cutoff_norm(2)-cutoff_norm(1);
    func(l) = (cutoff_norm(2)-i)/cutoff_normd;
  endif
end

fil_len = 2031;
fil = fir2(fil_len,pos,func);

bits = 16;
range = (2^bits-2)/2;
fil = round(fil*range)/range;

[h,w] = freqz(fil,1,10000);

f = pos;
m = func;

figure();
subplot(121);
plot(f,m,';target response;',w/pi,abs(h),';filter response;');
subplot(122);
plot(f,20*log10(m+1e-5),';target response (dB);',...
      w/pi,20*log10(abs(h)),';filter response (dB);');
