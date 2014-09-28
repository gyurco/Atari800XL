#include <stdio.h>

#include "curses_screen.h"
#include "linux_helper.h"
#include "linux_memory.h"

int zpu_main(void);

extern char* sdcard_filename;

int main(int argc, char** argv)
{
	if (argc > 1) {
		sdcard_filename = argv[1];
	}

	if (init_curses_screen()) {
		return 1;
	}

	init_memory();

	if (setjmp(exit_jmp_buf) == 0) {
		print_log("starting zpu_main\n");
		zpu_main();
	}

	deinit_curses_screen();
	return 0;
}
