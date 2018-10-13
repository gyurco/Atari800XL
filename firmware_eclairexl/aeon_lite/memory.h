#ifndef MEMORY_H
#define MEMORY_H

//1024k memory map
//(up to 576k atari mem)
//----
//64k (base)
//64-127  (64k)= freeze backup
//128k-255k=freezer ram (128k)
//256k-415k=carts (160k)
//288k-415k=dir cache (128k/shared)
//416k-447k=os rom/ram (32k)
//448k-511k=freezer rom
//512-1023 (512k ext)

#define SRAM_BASE ((void*) 0x200000)
#define SDRAM_BASE ((void*) 0x800000)

// Memory usage...
// 0x10000-0x1FFFF (0x810000 in zpu space) = freeze backup - 64k
// 0x20000-0x3FFFF (0x820000 in zpu space) = freezer ram (128k)
// 0x40000-0x67FFF (0x840000 in zpu space) = carts - 160k
// 0x48000-0x67FFF (0x848000 in zpu space) = directory cache - 128k
// 0x68000-0x6FFFF (0x868000 in zpu space) = os rom/basic rom - 32k
// 0x70000-0x7FFFF (0x870000 in zpu space) = freezer rom (64k)

#define INIT_MEM

#define DIR_INIT_MEM (SDRAM_BASE + 0x48000)
#define DIR_INIT_MEMSIZE 131072
#define FREEZE_MEM (SDRAM_BASE + 0x10000)
#define FREEZER_RAM_MEM (SDRAM_BASE + 0x20000)
#define FREEZER_ROM_MEM (SDRAM_BASE + 0x70000)
#define HAVE_FREEZER_ROM_MEM 1

#define CARTRIDGE_MEM (SDRAM_BASE + 0x40000) // Share with dir cache, long carts will be wired by dir listing

// offset in SDRAM area
#define ROM_OFS 0x68000


#define atari_regbase  ((void*) 0x10000)
#define atari_regmirror  ((void*) 0x20000)
#define zpu_regbase ((void*) 0x40000)
#define pokey_regbase ((void*) 0x40400)

#endif
