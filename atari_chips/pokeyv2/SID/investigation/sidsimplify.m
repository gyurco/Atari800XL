waves = sidwavereader;

i6581 = 21;
i8580 = 22;

iTri = 1 +1; 
iSaw = 2 +1; 
iPulse = 4 +1;

i_ST = iTri-1+iSaw-1+1;
iPST = iTri-1+iSaw-1+iPulse-1+1;
iP_T = iTri-1+iPulse-1+1;
iPS_ = iPulse-1+iSaw-1+1;

perfect(:,i_ST) = bitxor(waves(:,i8580,iSaw),waves(:,i8580,iTri));
perfect(:,iPST) = bitxor(bitxor(waves(:,i8580,iSaw),waves(:,i8580,iTri)),waves(:,i8580,iPulse));
perfect(:,iP_T) = bitxor(waves(:,i8580,iPulse),waves(:,i8580,iTri));
perfect(:,iPS_) = bitxor(waves(:,i8580,iPulse),waves(:,i8580,iSaw));

close all;
toplot = [i_ST iPST iP_T iPS_];
toplotleg = {'ST','PST','PT','PS'};
%toplot = [iPS_];
%toplotleg = {'PS'};
plot(waves(:,i6581,toplot))
title('6581');
legend(toplotleg);
figure;
plot(waves(:,i8580,toplot))
title('8580');
legend(toplotleg);
figure;
plot(perfect(:,toplot))
title('Perfect');
legend(toplotleg);