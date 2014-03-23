#ifndef debug_h
#define debug_h

void topofscreen();
void setxpos(int val);
void setypos(int val);
unsigned char toatarichar(int val);
unsigned char hextoatarichar(int val);
void plot(unsigned char val, int x, int y);
void plotnext(unsigned char val);
void plotnextnumber(unsigned short val);
void debug(char const * str);

void hexdump(char const * str, int length);
void hexdump_pure(char const * str, int length);

void initdebug(int onoff_in);

#endif //debug_h
