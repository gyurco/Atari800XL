#include "debug.h"
#include "pause.h"

#define ATARIBASE = 0x10000;
int xpos;
int ypos;
int onoff; // perhaps we can plot to another address buffer, which we can scroll through in the monitor?

int debugoffsetval;

void topofscreen()
{
	xpos = 0;
	ypos = 0;
}

void setxpos(int val)
{
	xpos = val;
}

void setypos(int val)
{
	ypos = val;
}

void initdebug(int onoff_in)
{
	xpos = 0;
	ypos = 0;
	onoff = onoff_in;
}

void nextline()
{
	int i;
	xpos=0;
	ypos+=1;
	if (ypos==24)
		ypos = 0;
	for (i=0;i!=40;++i)
		plot(0,i,ypos);

	//Delay100usX(5000);
}

unsigned char toatarichar(int val)
{
	int inv = val>=128;
	if (inv)
	{
		val-=128;
	}
	if (val>='A' && val<='Z')
	{
		val+=-'A'+33;
	}
	else if (val>='a' && val<='z')
	{
		val+=-'a'+33+64;
	}
	else if (val>='0' && val<='9')
	{
		val+=-'0'+16;	
	}
	else if (val>=32 && val<=47)
	{
		val+=-32;
	}
	else
	{
		val = 0;
	}
	if (inv)
	{
		val+=128;
	}
	return val;
}
unsigned char hextoatarichar(int val)
{
	if (val>=0 && val<=9)
	{
		val+=+16;	
	}
	else if (val>=10 && val<=15)
	{
		val+=-10+33;
	}
	return val;
}
void plot(unsigned char val, int x, int y)
{
	if (onoff == 0) return;

	unsigned char volatile * baseaddr = (unsigned char volatile *)(40000 + 0x10000);
	*(baseaddr + y*40+x) = val+debugoffsetval;
}
void debugoffset(int x)
{
	debugoffsetval = x;
}
void debug(char const * str)
{
	while (1)
	{
		int val = *str++;
		if (val==0) break;
		if (val=='\n') {nextline();continue;};

		plot(toatarichar(val),xpos,ypos);
		++xpos;
		if (xpos==40)
		{
			nextline();
		}
	}
	debugoffsetval = 0;
}

void plotnext(unsigned char val)
{
	plot(val,xpos,ypos);

	++xpos;
	if (xpos==40) nextline();
}

void plotnextnumber(unsigned short val)
{
	plotnext(hextoatarichar((val&0xf000)>>12));
	plotnext(hextoatarichar((val&0x0f00)>>8));
	plotnext(hextoatarichar((val&0x00f0)>>4));
	plotnext(hextoatarichar((val&0x000f)>>0));
	debugoffsetval = 0;
}

void hexdump(char const * str, int length)
{
	nextline();

	for (;length>0;--length)
	{
		unsigned char val= *str++;
		
		// LH 10 cols = char
		// RH 20 cols = hex

		plot(toatarichar(val),xpos,ypos);
		plot(hextoatarichar((val&0xf0) >> 4),xpos*2+20,ypos);
		plot(hextoatarichar(val&0xf),xpos*2+21,ypos);

		++xpos;
		if (xpos==10)
		{
			nextline();
		}
	}
	nextline();
}

void hexdump_pure(char const * str, int length)
{
	xpos = xpos&0xfffe;
	for (;length>0;--length)
	{
		unsigned char val= *str++;
		
		plot(hextoatarichar((val&0xf0) >> 4),xpos++,ypos);
		plot(hextoatarichar(val&0xf),xpos++,ypos);

		if (xpos==40)
		{
			nextline();
		}
	}
}

