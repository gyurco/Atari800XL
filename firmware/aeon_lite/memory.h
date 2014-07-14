#pragma once

// Memory usage...
// 0x90000-0x9FFFF (0x890000 in zpu space) = directory cache - 64k
// 0xA0000-0xBFFFF (0x8a0000 in zpu space) = freeze backup
// 0xC0000-0xDFFFF (0x8c0000 in zpu space) = os rom/basic rom

#define DIR_INIT_MEM 0x890000
#define FREEZE_MEM 0x8a0000
#define ROM_MEM 0xc0000

