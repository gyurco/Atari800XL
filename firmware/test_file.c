#include "simpledir.h"
#include "simplefile.h"
#include "fileselector.h"

//#include "fat/pff_file.h"
// XXX - BEST NOT to include this?

#include "stdio.h"
#include "stdlib.h"

int debug_pos = 0;
int debug_adjust = 0;
void wait_us(int us)
{
	usleep(us);
}

void char_out ( void* p, char c)
{
	putc(c, stderr);
}

int main(void)
{
	init_printf(NULL, char_out);

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
	entry = dir_next(entry);
	fprintf(stderr, " Name:%s", dir_filename(entry));
	struct SimpleFile * file = alloca(file_struct_size());
	file_open_dir(entry,file);

//char const * file_name(struct SimpleFile * file);
//enum SimpleFileStatus file_read(struct SimpleFile * file, void * buffer, int bytes, int * bytesread);
//enum SimpleFileStatus file_write(struct SimpleFile * file, void * buffer, int bytes, int * byteswritten);
//enum SimpleFileStatus file_seek(struct SimpleFile * file, int offsetFromStart);
//int file_size(struct SimpleFile * file);
	fprintf(stderr, " Size:%d\n---\n", file_size(file));

	int read = 0;
	char buffer[2048];
	file_seek(file,10);
	file_read(file,&buffer[0],2048,&read);
	int i;
	for (i=0; i!=read; ++i)
	{
		//fprintf(stderr,"%02x", buffer[i]);
		fprintf(stderr,"%c", buffer[i]);
	}

	fprintf(stderr,"\n\n");

	int written;
	file_seek(file,10);
	file_write(file,"Mark",4,&written); // in order to write 'mark' as position 10...
	//file_write_flush(); // Done automatically on next read, or can be forced with this...

	file_seek(file,512);
/*	for (i=0;i!=130;++i)
	{
		char towrite[9];
		sprintf(&towrite[0],"Mark:%03d",i);
		fprintf(stderr,"Writing \"%s\"\n",towrite);
		file_write(file,towrite,8,&written);
	}*/
	file_write(file,"Blah",4,&written);

	printf("\n*** WTF:%s - %s - %s\n",file_name(file), file_of("/WTF"),file_of("/BLAH/BOOP"));

	// So... for write can only seek to nearest 512...

	fprintf(stderr,"\n\n");
	file_seek(file,10);
	file_read(file,&buffer[0],2048,&read);
	for (i=0; i!=read; ++i)
	{
		//fprintf(stderr,"%02x", buffer[i]);
		fprintf(stderr,"%c", buffer[i]);
	}

	file_selector(file);

	return 0;
}


