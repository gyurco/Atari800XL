int compare_ext(char const * filenamein, char const * extin)
{
	int dot = 0;
	char filename[64];
	char ext[64];
	stricpy(filename,filenamein);
	stricpy(ext,extin);

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

