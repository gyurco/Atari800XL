#ifndef _FILE_H_
#define _FILE_H_

struct SimpleFile
{
	int num;
	int offset;
	int is_readonly;
	int size;
	int type;
	char ext;
};

#endif
