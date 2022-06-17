#include "integer.h"
#include "regs.h"
#include "file.h"
#include "simplefile.h"

/* these constants are just to satisfy menu.h */
char const * fil_type_rom;
char const * fil_type_bin;
char const * fil_type_car;
char const * fil_type_mem;
char const * fil_type_rpd;


int file_struct_size()
{
	return sizeof(struct SimpleFile);
}

void file_init(struct SimpleFile * file)
{
	file->num = 0;
	file->size = 0;
	file->type = 0;
	file->is_readonly = 1;
	file->offset = -1;
}

char *fname[] = {".ATR",".XEX",".ATX",".XFD"};
char const * file_name(struct SimpleFile * file)
{
	return fname[file->ext];
}

enum SimpleFileStatus file_open_name_in_dir(struct SimpleDirEntry * entry, char const * filename, struct SimpleFile * file)
{
	return SimpleFile_FAIL;
}

enum SimpleFileStatus file_open_name(char const * path, struct SimpleFile * file)
{
	return SimpleFile_FAIL;
}

enum SimpleFileStatus dir_init(void * mem, int space)
{
	return SimpleFile_FAIL;
}

struct SimpleDirEntry * dir_entries(char const * dirPath)
{
	return NULL;
}

DWORD cur_offset;
int cur_file;
BYTE sect_buffer[512];

BYTE cache_read(DWORD offset, int file)
{
	if(((offset & ~0x1FF) != (cur_offset & ~0x1FF)) || (cur_file != file))
	{
		int i;

		*zpu_out2 = offset >> 9;

		set_sd_read(0);
		set_sd_read(1 << file);
		while(!get_sd_ack()) {};
		set_sd_read(0);

		set_sd_secbuf_rd(1);
		for(i=0; i<512; i++) {
			set_sd_secbuf_addr(i);
			sect_buffer[i] = *zpu_in2;
		}
		set_sd_secbuf_rd(0);

		cur_offset = offset;
		cur_file = file;
	}
	return sect_buffer[offset & 0x1FF];
}

void cache_write(int file)
{
	int i;

	*zpu_out2 = cur_offset >> 9;

	set_sd_secbuf_we(1);
	for(i=0; i<512; i++) {
		set_sd_secbuf_addr(i);
		set_sd_secbuf_d(sect_buffer[i]);
	}
	set_sd_secbuf_we(0);

	set_sd_write(0);
	set_sd_write(1 << file);
	while(!get_sd_ack()) {};
	set_sd_write(0);
	while(get_sd_ack()) {};
}

void file_reset()
{
	cur_file = -1;
	cur_offset = -1;
}

int file_size(struct SimpleFile * file)
{
	return file->size;
}

int file_readonly(struct SimpleFile * file)
{
	return file->is_readonly;
}

int file_type(struct SimpleFile * file)
{
	return file->type;
}

enum SimpleFileStatus file_read(struct SimpleFile *file, void *buffer, int bytes, int *bytesread)
{
	if((file->offset >= 0) && (file->size > file->offset) && (bytes > 0))
	{
		if((file->offset + bytes) > file->size) bytes = file->size - file->offset;
		*bytesread = bytes;

		while(bytes--) *(unsigned char *)buffer++ = cache_read(file->offset++, file->num); 
		return SimpleFile_OK;
	}

	*bytesread = 0;
	return SimpleFile_FAIL;
}

enum SimpleFileStatus file_seek(struct SimpleFile * file, int offsetFromStart)
{
	if((file->size > 0) && (file->size >= offsetFromStart))
	{
		file->offset = offsetFromStart;
		return SimpleFile_OK;
	}
	return SimpleFile_FAIL;
}

enum SimpleFileStatus file_write(struct SimpleFile *file, void *buffer, int bytes, int *byteswritten)
{
	if((file->offset >= 0) && (file->size > file->offset) && (bytes > 0))
	{
		if((file->offset + bytes) > file->size) bytes = file->size - file->offset;
		*byteswritten = bytes;

		while(bytes>0)
		{
			cache_read(file->offset, file->num);
			do
			{
				sect_buffer[file->offset & 0x1FF] = *(unsigned char*) buffer;
				bytes--;
				file->offset++;
				buffer++;
			}
			while((file->offset & 0x1FF) && (bytes>0));
			cache_write(file->num);
		}
		return SimpleFile_OK;
	}
	
	return SimpleFile_FAIL;
}

enum SimpleFileStatus file_write_flush()
{
	return SimpleFile_FAIL;
}

int file_mount(struct SimpleFile * file, unsigned char num, int size, char ext)
{
	file->num = num;
	file->offset = -1;
	file->size = size;
	file->is_readonly = 0;
	file->ext = ext & 0x3;
	file_reset();
}
