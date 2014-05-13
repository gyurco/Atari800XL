#include "simplefile.h"
#include "simpledir.h"
#include "joystick.h"
#include "regs.h" // NO NEED!!! 
#include "printf.h"
#include "fileutils.h"

extern int debug_pos; // ARG!
extern int debug_adjust; // ARG!

// TODO!
#define MAX_PATH_LENGTH (9*5 + 8+3+1 + 1) 

int filter(struct SimpleDirEntry * entry)
{
	if (dir_is_subdir(entry)) return 1;
	char const * f = dir_filename(entry);
	return (compare_ext(f,"ATR") || compare_ext(f,"XFD") || compare_ext(f,"XEX"));
}

void file_selector(struct SimpleFile * file)
{
	char dir[MAX_PATH_LENGTH] = "";
	for (;;)
	{
		// TODO last selected dir...
		struct SimpleDirEntry * entry = dir_entries_filtered(dir,filter);

		// Count how many we have
		int entries = 0;
		struct SimpleDirEntry * temp_entry = entry;
		while (temp_entry)
		{
			++entries;
			temp_entry = dir_next(temp_entry);
		}

		// Selected item
		int pos = 0;

		struct joystick_status joy;
		joy.x_ = joy.y_ = joy.fire_ = 0;

		for (;;)
		{
			if (pos<0) pos = 0;
			if (pos>=entries) pos = entries-1;

			// render
			{
				// find which chunk to render
				int startpos = pos-20;
				if (startpos<0) startpos=0;

				// get the dir entries for these
				struct SimpleDirEntry * render_entry = entry;
				int skip = startpos;
				while (skip-->0)
				{
					render_entry =  dir_next(render_entry);
				}

				// clear the screen
				clearscreen();

				// find selected entry
				struct SimpleDirEntry * sel_entry = entry;
				skip = pos;
				while (skip-->0)
				{
					sel_entry =  dir_next(sel_entry);
				}

				// output the new entries
				int line;
				for (line=0; line<44; ++line)
				{
					if (!render_entry) break;
					
					debug_pos = line*20;
					if (render_entry == sel_entry)
					{
						debug_adjust = 128;
					}
					else
					{
						debug_adjust = 0;
					}
					if (dir_is_subdir(render_entry))
					{
						printf("DIR:");
					}
					printf("%s",dir_filename(render_entry));

					render_entry = dir_next(render_entry);
				}

				debug_pos = 40*23;
				if (sel_entry)
				{
					printf("%s %s %d %d %d",dir_is_subdir(sel_entry) ? "DIR":"", dir_filename(sel_entry), joy.x_, joy.y_, pos);
				}
			}

			// Slow it down a bit
			wait_us(100000);

			// move
			joystick_wait(&joy,WAIT_QUIET);
			joystick_wait(&joy,WAIT_EITHER);
			
			if (joy.fire_)
			{
				int i = pos;
				while(i--)
				{
					if (!entry) break;
					entry = dir_next(entry);
				}

				if (entry)
				{
					if (!dir_is_subdir(entry))
					{
						file_open_dir(entry, file);
						return;
					}
					else
					{
						char const *f = dir_filename(entry);
						if (strcmp("..",f)==0)
						{
							int x = strlen(dir);
							while (x-->0)
							{
								if (dir[x] == '/')
								{
									dir[x] = '\0';
									break;
								}
							}
							//printf("\nDIR UP! %s\n",dir);
						}
						else
						{
							strcpy(dir + strlen(dir),"/");
							strcpy(dir + strlen(dir),f);
							//printf("\nDIR DOWN:%s -> %s\n",f,dir);
						}
					}
					break;
				}

				return;
			}
			
			pos += joy.x_;
			pos += joy.y_*2;
		}
	}
}

