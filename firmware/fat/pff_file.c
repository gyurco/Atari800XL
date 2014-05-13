#include "pff_file.h"

#include "pff.h"
#include "utils.h"
#include "diskio.h"
#include "simplefile.h"
#include "printf.h"

struct SimpleFile * openfile;

void * dir_cache;
int dir_cache_size;

FATFS fatfs;
DIR dir;
FILINFO filinfo;

int write_pending;

enum SimpleFileStatus translateStatus(FRESULT res)
{
	return res == FR_OK ? SimpleFile_OK: SimpleFile_FAIL;
}

enum SimpleFileStatus translateDStatus(DSTATUS res)
{
	return res == RES_OK ? SimpleFile_OK: SimpleFile_FAIL;
}

char const * file_of(char const * path)
{
	char const * start = path + strlen(path);
	while (start!=path)
	{
		--start;
		if (*start == '/')
		{
			--start;
			break;
		}
	}
	return start;
}

void dir_of(char * dir, char const * path)
{
	char const * end = file_of(path);
	if (end != path) 
	{
		int len = end-path;
		while (len--)
		{
			*dir++ = *path++;
		}
	}

	*dir = '\0';
	return;
}

char const * file_name(struct SimpleFile * file)
{
	return file_of(&file->path[0]);
}

void file_check_open(struct SimpleFile * file)
{
	if (openfile!=file)
	{
		file_write_flush();

		pf_open(&file->path[0]);
		openfile = file;
	}
}

enum SimpleFileStatus file_read(struct SimpleFile * file, void * buffer, int bytes, int * bytesread)
{
	WORD bytesread_word;
	FRESULT res;

	file_write_flush();
	file_check_open(file);

	res = pf_read(buffer, bytes, &bytesread_word);
	*bytesread = bytesread_word;

	return translateStatus(res);
}

enum SimpleFileStatus file_write(struct SimpleFile * file, void * buffer, int bytes, int * byteswritten)
{
	WORD byteswritten_word;
	FRESULT res;

	printf("went\n");

	file_check_open(file);

	int rem = bytes;
	while (rem>0)
	{
		int sector = fatfs.fptr>>9;
		int pos = fatfs.fptr&0x1ff;

		int bytes_this_cycle = rem;
		if (bytes_this_cycle>(512-pos))
			bytes_this_cycle = 512-pos;

		printf("file_write:%d/%d - %d/%d\n",sector,pos,bytes_this_cycle,bytes);

		if (sector != write_pending)
		{
			file_write_flush();
		}

		if (write_pending <0)
		{
			// read the sector into our 512 byte buffer...
			pf_lseek(sector<<9);
			int fptr = fatfs.fptr;

			char temp_buffer[1];
			pf_read(&temp_buffer[0], 1, &byteswritten_word);

			printf("Writing initial pos:%d\n",pos);

			// seek to the initial pos
			fatfs.fptr = fptr + pos;

			write_pending = sector;
		}

		res = disk_writep(buffer, pos, bytes_this_cycle);

		fatfs.fptr += bytes_this_cycle;
		rem-=bytes_this_cycle;
		buffer+=bytes_this_cycle;
	}
	*byteswritten = bytes;

	printf("wend\n");
	return translateStatus(res);
}

enum SimpleFileStatus file_write_flush()
{
	if (write_pending >= 0)
	{
		printf("wflush\n");
		disk_writeflush();
		write_pending = -1;
	}
	return SimpleFile_OK;
}

enum SimpleFileStatus file_seek(struct SimpleFile * file, int offsetFromStart)
{
	FRESULT res;

	int location = offsetFromStart>>9;
	if (write_pending >=0 && write_pending != offsetFromStart)
	{
		printf("flush on seek\n");
		file_write_flush();
	}

	file_check_open(file);

	pf_lseek(offsetFromStart);
	return translateStatus(res);
}

int file_size(struct SimpleFile * file)
{
	return file->size;
}

int file_struct_size()
{
	return sizeof(struct SimpleFile);
}

enum SimpleFileStatus file_open_name(char const * path, struct SimpleFile * file)
{
	char dirname[MAX_DIR_LENGTH];
	char const * filename = file_of(path);
	dir_of(&dirname[0], path);

	file_write_flush();

	printf("filename:%s dirname:%s ", filename,&dirname[0]);

	struct SimpleDirEntry * entry = dir_entries(&dirname[0]);
	while (entry)
	{
		printf("%s ",entry->filename_ptr);
		if (0==strcmp(filename,entry->filename_ptr))
		{
			return file_open_dir(entry, file);
		}
		entry = entry->next;
	}

	return SimpleFile_FAIL;
}

enum SimpleFileStatus file_open_dir(struct SimpleDirEntry * dir, struct SimpleFile * file)
{
	FRESULT res;

	strcpy(&file->path[0],dir->path);
	file->size = dir->size;

	file_write_flush();

	res = pf_open(&file->path[0]);
	openfile = file;

	return translateStatus(res);
}

enum SimpleFileStatus dir_init(void * mem, int space)
{
	FRESULT fres;
	DSTATUS res;

	write_pending = -1;

	printf("dir_init\n");

	dir_cache = mem;
	dir_cache_size = space;

	printf("disk_init go\n");
	res = disk_initialize();
	printf("disk_init done\n");
	if (res!=RES_OK) return translateDStatus(res);

	printf("pf_mount\n");
	fres = pf_mount(&fatfs);
	printf("pf_mount done\n");

	return translateStatus(fres);
}

// Read entire dir into memory (i.e. give it a decent chunk of sdram)
struct SimpleDirEntry * dir_entries(char const * dirPath)
{
	return dir_entries_filtered(dirPath,0);
}

struct SimpleDirEntry * dir_entries_filtered(char const * dirPath,int(* filter)(struct SimpleDirEntry *))
{
	int room = dir_cache_size/sizeof(struct SimpleDirEntry);

	file_write_flush();

	printf("opendir ");
	if (FR_OK != pf_opendir(&dir,dirPath))
	{
		printf("FAIL ");
		return 0;
	}
	printf("OK ");

	struct SimpleDirEntry * prev = (struct SimpleDirEntry *)dir_cache;
	strcpy(prev->path,"..");
	prev->filename_ptr = prev->path;
	prev->size = 0;
	prev->is_subdir = 1;
	--room;

	struct SimpleDirEntry * entry = 0;
	while (FR_OK == pf_readdir(&dir,&filinfo) && filinfo.fname[0]!='\0')
	{
		char * ptr;

		if (filinfo.fattrib & AM_SYS)
		{
			continue;
		}
		if (filinfo.fattrib & AM_HID)
		{
			continue;
		}

		if (room)
		{
			entry = prev+1;
			--room;
		}
		else
		{
			break; // OUT OF ROOM!
		}

		printf("next %x %d ",entry,room);

		entry->is_subdir = (filinfo.fattrib & AM_DIR) ? 1 : 0;

		printf("%s ",filinfo.fname);

		strcpy(&entry->path[0],dirPath);
		ptr = &entry->path[0];
		ptr += strlen(&entry->path[0]);
		*ptr++ = '/';
		entry->filename_ptr = ptr;
		strcpy(ptr,filinfo.fname);
		entry->size = filinfo.fsize;

		entry->next = 0;

		if (filter && !filter(entry))
		{
			continue;	
		}

		if (prev)
			prev->next = entry;
		prev = entry;

		printf("n %d %d %x ",filinfo.fsize, entry->size, entry->next);
	}

	printf("dir_entries done ");

	entry->next = 0;
	return (struct SimpleDirEntry *) dir_cache;
}

char const * dir_path(struct SimpleDirEntry * entry)
{
	return &entry->path[0];
}

char const * dir_filename(struct SimpleDirEntry * entry)
{
	return entry->filename_ptr;
}

int dir_filesize(struct SimpleDirEntry * entry)
{
	return entry->size;
}

struct SimpleDirEntry * dir_next(struct SimpleDirEntry * entry)
{
	return entry->next;
}

int dir_is_subdir(struct SimpleDirEntry * entry)
{
	return entry->is_subdir;
}


