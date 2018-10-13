#ifndef MEMORY_H
#define MEMORY_H

//512k memory map
//(up to 320k atari mem)
//----
//64k (base)
//64-127  (64k)= freeze backup
//128-223 (96k)= carts 
//160-223 (64k)= dir cache
//224-255 (32k)= os rom/ram
//256 (ext)

#define SRAM_BASE ((void*) 0x200000)
#define SDRAM_BASE ((void*) 0x800000)

// Memory usage...
// 0x20000-0x37FFF (0x820000 in zpu space) = carts - 96k
// 0x28000-0x37FFF (0x820000 in zpu space) = directory cache - 64k
// 0x10000-0x1FFFF (0x810000 in zpu space) = freeze backup - 64k
// 0x38000-0x3FFFF (0x838000 in zpu space) = os rom/basic rom - 32k

#define INIT_MEM

#define DIR_INIT_MEM (SDRAM_BASE + 0x28000)
#define DIR_INIT_MEMSIZE 65536
#define FREEZE_MEM (SDRAM_BASE + 0x10000)

#define CARTRIDGE_MEM (SDRAM_BASE + 0x20000) // Share with dir cache, long carts will be wired by dir listing

// offset in SDRAM area
#define ROM_OFS 0x38000


#define atari_regbase  ((void*) 0x10000)
#define atari_regmirror  ((void*) 0x20000)
#define zpu_regbase ((void*) 0x40000)
#define pokey_regbase ((void*) 0x40400)

#endif
