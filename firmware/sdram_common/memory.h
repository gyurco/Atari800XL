#pragma once

// Memory usage...
// 0x410000-0x41FFFF (0xc10000 in zpu space) = directory cache - 64k
// 0x420000-0x43FFFF (0xc20000 in zpu space) = freeze backup
// 0x700000-0x77FFFF (0xf00000 in zpu space) = os rom/basic rom

#define DIR_INIT_MEM 0xc10000
#define FREEZE_MEM 0xc20000
#define ROM_MEM 0x700000

