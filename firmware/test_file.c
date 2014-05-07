#include "simpledir.h"
#include "simplefile.h"

//#include "fat/pff_file.h"
// XXX - BEST NOT to include this?

#include "stdio.h"
#include "stdlib.h"

int main(void)
{
	char * mem = (char *)malloc(8192);
	if (SimpleFile_OK != dir_init(mem, 8192))
	{
		fprintf(stderr,"Failed to open dir!");
		return -1;
	}
	struct SimpleDirEntry * entry = dir_entries("");
	while (entry)
	{
		fprintf(stderr, "Path:%s", dir_path(entry));
		fprintf(stderr, " Name:%s", dir_filename(entry));
		fprintf(stderr, " Size:%d", dir_filesize(entry));
		fprintf(stderr, " Subdir:%d\n", dir_is_subdir(entry));

		entry = dir_next(entry);
	}

	fprintf(stderr,"\n\n");

	entry = dir_entries("/UAE4ALL");
	while (entry)
	{
		fprintf(stderr, "Path:%s", dir_path(entry));
		fprintf(stderr, " Name:%s", dir_filename(entry));
		fprintf(stderr, " Size:%d", dir_filesize(entry));
		fprintf(stderr, " Subdir:%d\n", dir_is_subdir(entry));

		entry = dir_next(entry);
	}

	fprintf(stderr,"\n\n");

	entry = dir_entries("/UAE4ALL/DATA");
	while (entry)
	{
		fprintf(stderr, "Path:%s", dir_path(entry));
		fprintf(stderr, " Name:%s", dir_filename(entry));
		fprintf(stderr, " Size:%d", dir_filesize(entry));
		fprintf(stderr, " Subdir:%d\n", dir_is_subdir(entry));

		entry = dir_next(entry);
	}


	fprintf(stderr,"\n\n");
//enum SimpleFileStatus file_open_name(char const * path, struct SimpleFile * file);
//enum SimpleFileStatus file_open_dir(struct SimpleDirEntry * filename, struct SimpleFile * file);
	entry = dir_entries("/UAE4ALL");
	fprintf(stderr, " Name:%s", dir_filename(entry));
	struct SimpleFile * file = alloca(file_struct_size());
	file_open_dir(entry,file);

//char const * file_name(struct SimpleFile * file);
//enum SimpleFileStatus file_read(struct SimpleFile * file, void * buffer, int bytes, int * bytesread);
//enum SimpleFileStatus file_write(struct SimpleFile * file, void * buffer, int bytes, int * byteswritten);
//enum SimpleFileStatus file_seek(struct SimpleFile * file, int offsetFromStart);
//int file_size(struct SimpleFile * file);
	fprintf(stderr, " Size:%d", file_size(file));

	int read = 0;
	char buffer[1024];
	file_seek(file,100);
	file_read(file,&buffer[0],1024,&read);
	int i;
	for (i=0; i!=read; ++i)
	{
		//fprintf(stderr,"%02x", buffer[i]);
		fprintf(stderr,"%c", buffer[i]);
	}

	return 0;
}


