#include "printf.h"

#include "utils.h"

int compare_ext(char const * filenamein, char const * extin)
{
	int dot = 0;
	char filename[256];
	char ext[4];
	stricpy(filename,filenamein);
	stricpy(ext,extin);

	//printf("WTFA:%s %s\n",filenamein, extin);
	//printf("WTFB:%s %s\n",filename, ext);

	while (1)
	{
		if (filename[dot] == '\0')
			break;
		if (filename[dot] != '.')
		{
			++dot;
			continue;
		}
		if (filename[dot+1] == ext[0])
			if (filename[dot+2] == ext[1])
				if (filename[dot+3] == ext[2])
				{
					return 1;
					break;
				}
		break;
	}

	return 0;
}

