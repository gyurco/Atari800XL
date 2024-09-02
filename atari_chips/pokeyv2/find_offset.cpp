#include <stdio.h>
#include <string>

int main(int argc, char **  argv)
{
	if (argc!=5)
	{
		fprintf(stderr,"Expected pattern_file,pattern_offset,pattern_len,match_file\n");
		return -1;
	}

	std::string pattern = argv[1];
	int offset = atoi(argv[2]);
	size_t len = atoi(argv[3]);
	std::string find_in_here = argv[4];
	
	FILE * p = fopen(pattern.c_str(),"rb");
	if (!p)
	{
		fprintf(stderr,"Unable to open %s\n",pattern.c_str());
		return -1;
	}
	fseek(p,offset,SEEK_SET);
	unsigned char * data = (unsigned char *)malloc(len);
	if (fread(data,1,len,p)!=len)
	{
		fprintf(stderr,"Unable to read pattern\n");
		return -1;
	}
	fclose(p);

	FILE * f = fopen(find_in_here.c_str(),"rb");
	if (!f)
	{
		fprintf(stderr,"Unable to open %s\n",find_in_here.c_str());
		return -1;
	}
	int file_offset = 0;
	unsigned char * match = (unsigned char *)malloc(len);
	bool found = false;
	while (!found)
	{
		fseek(f,file_offset,SEEK_SET);
		if (fread(match,1,len,f) !=len)
			break;
		found = true;
		for (size_t i=0;i!=len;++i)
		{
			//printf("%d:%d:%02x %02x\n",file_offset,i,match[i],data[i]);
			if (match[i]!=data[i])
			{
				found = false;
				break;
			}
		}
		if (found)
		{
			printf("%08x",file_offset);
			break;
		}
		++file_offset;
	}
	fclose(f);

	free(match);
	free(data);

	if (found)
		return 0;
	else
		return -1;
}

