  customscalepoly = 1024;
  customscaleraw = 400;
  
  res = [
    1,1440 ,1440,312,312+313-1; %pal 576i  
    0,1440 ,720,312,625-1; %pal 576p    
    0,1440 ,1280,312,750; %720p pal
    1,1440 ,1920,312.5,562+563; %pal 1080i
    
    1,1440 ,1440,262,262+263-1; %ntsc 480i    
    0,1440 ,720,262,525-1; %ntsc 480p       
    0,1440 ,1280,262,750; %720p ntsc    
    1,1440 ,1920,262.5,562+563;  %ntsc 1080i        
  ]; 
  
  resname = {'pal576i','pal576p','pal720p','pal1080i','ntsc480i','ntsc480p','ntsc720p','ntsc1080i'}; 

  for i=1:size(res,1)
    
    interlace = res(i,1);
    x_pre = res(i,2);
    x = res(i,3);
    y_pre = res(i,4);
    y = res(i,5);
    
    if x_pre>x
      x_pre = x_pre/2;
      xaddrskip = 2;
    else
      xaddrskip = 1;
    end
    
    HSR = x_pre/x;
    VSR = y_pre/y;
    
    %area
    xdelta = customscaleraw*HSR;
    ydelta = customscaleraw*VSR;  
    TA = customscaleraw*HSR*customscaleraw*VSR;
    
    adj = 65536/TA; 
    TA = TA*adj;  
    xdelta = round(xdelta);
    ydelta2 = round(ydelta*adj*2);  
    ydelta = round(ydelta*adj);
   
   
    customscalex = round(customscaleraw); 
    customscaley = round(customscaleraw*adj);
    
    
    %fprintf('%10s x:%4d y:%4d xthreshold:%d xdelta:%d ythreshold:%d ydelta:%d(%d) TA:%d\n',...
    %resname{i},x,y,customscalex,xdelta,customscaley,ydelta,ydelta2,TA');     
    fprintf('%d,%d,%d,%d,%d,%d, /*%s*/\n',customscalex,xdelta,customscaley,ydelta,ydelta*(interlace+1),xaddrskip,resname{i});
    
    %poly
    xdelta = customscalepoly*HSR;
    ydelta = customscalepoly*VSR;  
    
    xdelta = round(xdelta);
    ydelta2 = round(ydelta*2);  
    ydelta = round(ydelta);
   
   
    customscalex = round(customscalepoly); 
    customscaley = round(customscalepoly);
    
    fprintf('%d,%d,%d,\n',xdelta,ydelta*(interlace+1),xaddrskip);
    
    %fprintf('%10s x:%4d y:%4d xdelta:%6d ydelta:%6d(%6d)\n',...
    % resname{i},x,y,xdelta,ydelta,ydelta2);        
  end  

