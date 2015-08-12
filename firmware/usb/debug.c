#include "debug.h"

#include "stdarg.h"

#include "printf/printf.h"

struct SimpleFile * usb_file;

void usb_log_init(struct SimpleFile * file)
{
	file_open_name("/usb.log", file);
	if (file_size(file)>=65536 && file_readonly(file)==0)
		usb_file = file;
	else
		usb_file = 0;
}

void usb_log(char *fmt, ...)
{
	va_list va;
	va_start(va,fmt);

	if (usb_file)
	{
		char buffer[256];
		sprintf(&buffer[0],fmt,va);

		int byteswritten = 0;
		file_write(usb_file,(void *)buffer,strlen(buffer),&byteswritten);
	}

	va_end(va);
}

