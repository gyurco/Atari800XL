#pragma once

// Memory usage...
// 0x410000-0x44FFFF (0xc10000 in zpu space) = directory cache - 256k
// 0x450000-0x46FFFF (0xc50000 in zpu space) = freeze backup
// 0x700000-0x77FFFF (0xf00000 in zpu space) = os rom/basic rom

#define DIR_INIT_MEM 0xc10000
#define DIR_INIT_MEMSIZE 262144
#define FREEZE_MEM 0xc50000
#define ROM_MEM 0x700000

