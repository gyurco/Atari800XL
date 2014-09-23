#ifndef MEMORY_H
#define MEMORY_H

#define SRAM_BASE ((void*) 0x200000)
#define SDRAM_BASE ((void*) 0x800000)

// Memory usage...
// 0x410000-0x44FFFF (0xc10000 in zpu space) = directory cache - 256k
// 0x450000-0x46FFFF (0xc50000 in zpu space) = freeze backup
// 0x700000-0x77FFFF (0xf00000 in zpu space) = os rom/basic rom

#define DIR_INIT_MEM (SDRAM_BASE + 0x410000)
#define DIR_INIT_MEMSIZE 262144
#define FREEZE_MEM (SDRAM_BASE + 0x450000)

// offset into SDRAM
#define ROM_OFS 0x700000

#define atari_regbase  ((void*) 0x10000)
#define atari_regmirror  ((void*) 0x20000)
#define config_regbase ((void*) 0x40000)

#endif
