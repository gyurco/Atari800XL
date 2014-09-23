#include "stdio.h"
//#include <string.h>

//#define stricmp strncasecmp

int strcmp(char const * a, char const * b);
int stricmp(char const * a, char const * b);
void strcpy(char * dest, char const * src);
void stricpy(char * dest, char const * src);
int strlen(char const * a);
int strcmp(char const * a, char const * b)
{
	while (*a || *b)
	{
		if (*a<*b)
			return -1;
		else if (*a>*b)
			return 1;

		++a;
		++b;
	}
	return 0;
}

int stricmp(char const * a, char const * b)
{
	char buffer[128];
	char buffer2[128];
	stricpy(&buffer[0],a);
	stricpy(&buffer2[0],b);
	return strcmp(&buffer[0],&buffer2[0]);
}

void strcpy(char * dest, char const * src)
{
	while (*dest++=*src++);
}

void stricpy(char * dest, char const * src)
{
	while (*src)
	{
		char val = *src++;
		if (val>='A' && val<='Z') val+=-'A'+'a';

		*dest++ = val;
	}
	*dest = '\0';
}

int strlen(char const * a)
{
	int count;
	for (count=0; *a; ++a,++count);
	return count;
}

int compare_ext(char const * filename, char const * ext)
{
	int dot = 0;
	//printf("WTFA:%s %s\n",filenamein, extin);
	//printf("WTFB:%s %s\n",filename, ext);

	char const * end = strlen(filename) + filename;
	while (--end != filename)
	{
		if (*end == '.')
			break;
	}
	if (0==stricmp(end+1,ext)) return 1;

	return 0;
}

//int compare_ext(char const * filename, char const * ext)
//{
//        int dot = 0;
//        //printf("WTFA:%s %s\n",filenamein, extin);
//        //printf("WTFB:%s %s\n",filename, ext);
//
//        char const * end = strlen(filename) + filename;
//        while (--end != filename)
//        {
//                if (*end == '.')
//                        break;
//        }
//        if (0==stricmp(end+1,ext,1000)) return 1;
//
//        return 0;
//}

int main(void)
{
	fprintf(stderr,"%d %d %d %d\n",
		compare_ext("Elektra Glide.ATR","atr"),
		compare_ext("Elektra Glide (1985)(English Software Company).xex","XEX"),
		compare_ext("International Karate.atr","atr"),
		compare_ext("World Karate Championship.atx","xex"));

	return 0;
}

