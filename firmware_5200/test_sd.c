
#include "simpledir.h"
#include "simplefile.h"
#include "fileselector.h"

//#include "fat/pff_file.h"
// XXX - BEST NOT to include this?
char USER_DIR[]="/";
char ROM_DIR[]="/";

#include "stdio.h"
#include "stdlib.h"

int debug_pos = 0;
int prev_debug_pos = 0;
int debug_adjust = 0;
void wait_us(int us)
{
	usleep(us);
}

void char_out ( void* p, char c)
{
	if (debug_pos!=prev_debug_pos)
	{
		fprintf(stderr,"\n");
	}
	//fprintf(stderr,"\n%dWTFWTF\n", debug_pos);
	if (debug_adjust == 128)
	{
		putc('*',stderr);
	}
	putc(c, stderr);
	++debug_pos;
	prev_debug_pos = debug_pos;
}
int main(void)
{
	init_printf(NULL, char_out);

	char * mem = (char *)malloc(65536);
	if (SimpleFile_OK != dir_init(mem, 65536))
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
}

