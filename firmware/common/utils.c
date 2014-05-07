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

void strcpy(char * dest, char const * src)
{
	while (*dest++=*src++);
}

int strlen(char const * a)
{
	int count;
	for (count=0; *a; ++a,++count);
	return count;
}

