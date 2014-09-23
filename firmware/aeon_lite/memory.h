#ifndef MEMORY_H
#define MEMORY_H

#define SRAM_BASE ((void*) 0x200000)
#define SDRAM_BASE ((void*) 0x800000)

// Memory usage...
// 0x90000-0x9FFFF (0x890000 in zpu space) = directory cache - 64k
// 0xA0000-0xBFFFF (0x8a0000 in zpu space) = freeze backup
// 0xC0000-0xDFFFF (0x8c0000 in zpu space) = os rom/basic rom

#define DIR_INIT_MEM (SDRAM_BASE + 0x90000)
#define DIR_INIT_MEMSIZE 65536
#define FREEZE_MEM (SDRAM_BASE + 0xa0000)

// offset in SDRAM area
#define ROM_OFS 0xc0000

#define atari_regbase  ((void*) 0x10000)
#define atari_regmirror  ((void*) 0x20000)
#define config_regbase ((void*) 0x40000)

#endif
