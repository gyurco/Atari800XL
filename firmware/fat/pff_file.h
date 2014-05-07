#pragma once

#include "simplefile.h"
#include "simpledir.h"

#define MAX_DIR_LENGTH (9*5+1)
#define MAX_FILE_LENGTH (8+3+1+1)
#define MAX_PATH_LENGTH (9*5 + 8+3+1 + 1)

// Do not access these directly... They vary by architecture, just the simplefile/simpledir interface is the same
struct SimpleFile
{
	char path[MAX_PATH_LENGTH];
	int size;
};

struct SimpleDirEntry
{
	char path[MAX_PATH_LENGTH];
	char * filename_ptr;
	int size;
	int is_subdir;
	struct SimpleDirEntry * next; // as linked list - want to allow sorting...
};

