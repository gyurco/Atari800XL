#include <stdint.h>
#include <string.h>
#include "regs.h"
#include "memory.h"
#include "linux_memory.h"

int volatile * zpu_in1;
int volatile * zpu_in2;
int volatile * zpu_in3;
int volatile * zpu_in4;

int volatile * zpu_out1;
int volatile * zpu_out2;
int volatile * zpu_out3;
int volatile * zpu_out4;

int volatile * zpu_pause;

int volatile * zpu_spi_data;
int volatile * zpu_spi_state;

int volatile * zpu_sio;

int volatile * zpu_board;

int volatile * zpu_spi_dma;

unsigned char volatile * zpu_pokey_audf0;
unsigned char volatile * zpu_pokey_audc0;
unsigned char volatile * zpu_pokey_audf1;
unsigned char volatile * zpu_pokey_audc1;
unsigned char volatile * zpu_pokey_audf2;
unsigned char volatile * zpu_pokey_audc2;
unsigned char volatile * zpu_pokey_audf3;
unsigned char volatile * zpu_pokey_audc3;

unsigned char volatile * zpu_pokey_audctl;

unsigned char volatile * zpu_pokey_skrest;
unsigned char volatile * zpu_pokey_serout;
unsigned char volatile * zpu_pokey_irqen;
unsigned char volatile * zpu_pokey_skctl;

unsigned char volatile * atari_nmien;
unsigned char volatile * atari_dlistl;
unsigned char volatile * atari_dlisth;
unsigned char volatile * atari_colbk;
unsigned char volatile * atari_colpf1;
unsigned char volatile * atari_colpf2;
unsigned char volatile * atari_colpf3;
unsigned char volatile * atari_colpf0;
unsigned char volatile * atari_prior;
unsigned char volatile * atari_random;
unsigned char volatile * atari_porta;
unsigned char volatile * atari_portb;
unsigned char volatile * atari_trig0;
unsigned char volatile * atari_chbase;
unsigned char volatile * atari_chactl;
unsigned char volatile * atari_dmactl;
unsigned char volatile * atari_skctl;

void* SRAM_BASE;
void* SDRAM_BASE;
void* atari_regbase;
void* atari_regmirror;
void* config_regbase;
void* CARTRIDGE_MEM;

#define SRAM_SIZE (512*1024)
#define SDRAM_SIZE (8*1024*1024)
#define ATARI_SIZE (64*1024)
#define CONFIG_SIZE (256)
#define CARTRIDGE_SIZE (2*1024*1024)

uint8_t sram_memory[SRAM_SIZE];
uint32_t sdram_memory[SDRAM_SIZE / 4];
uint8_t atari_memory[ATARI_SIZE];
uint8_t atari_mirror_memory[ATARI_SIZE];
uint32_t config_memory[CONFIG_SIZE/4];
uint32_t cartridge_memory[CARTRIDGE_SIZE / 4];

void init_memory(void)
{
	memset(sram_memory, SRAM_SIZE, 0);
	memset(sdram_memory, SDRAM_SIZE, 0);
	memset(atari_memory, ATARI_SIZE, 0);
	memset(atari_mirror_memory, ATARI_SIZE, 0);
	memset(config_memory, CONFIG_SIZE, 0);
	memset(cartridge_memory, CARTRIDGE_SIZE, 0);

	SRAM_BASE = sram_memory;
	SDRAM_BASE = sdram_memory;
	atari_regbase = atari_memory;
	atari_regmirror = atari_mirror_memory;
	config_regbase = config_memory;
	CARTRIDGE_MEM = cartridge_memory;

	zpu_in1 = (int *)(0*4+config_regbase);
	zpu_in2 = (int *)(1*4+config_regbase);
	zpu_in3 = (int *)(2*4+config_regbase);
	zpu_in4 = (int *)(3*4+config_regbase);

	zpu_out1 = (int *)(4*4+config_regbase);
	zpu_out2 = (int *)(5*4+config_regbase);
	zpu_out3 = (int *)(6*4+config_regbase);
	zpu_out4 = (int *)(7*4+config_regbase);

	zpu_pause = (int *)(8*4+config_regbase);

	zpu_spi_data = (int *)(9*4+config_regbase);
	zpu_spi_state = (int *)(10*4+config_regbase);

	zpu_sio = (int *)(11*4+config_regbase);

	zpu_board = (int *)(12*4+config_regbase);

	zpu_spi_dma = (int *)(13*4+config_regbase);

	zpu_pokey_audf0 = (unsigned char *)(0x10*4+config_regbase);
	zpu_pokey_audc0 = (unsigned char *)(0x11*4+config_regbase);
	zpu_pokey_audf1 = (unsigned char *)(0x12*4+config_regbase);
	zpu_pokey_audc1 = (unsigned char *)(0x13*4+config_regbase);
	zpu_pokey_audf2 = (unsigned char *)(0x14*4+config_regbase);
	zpu_pokey_audc2 = (unsigned char *)(0x15*4+config_regbase);
	zpu_pokey_audf3 = (unsigned char *)(0x16*4+config_regbase);
	zpu_pokey_audc3 = (unsigned char *)(0x17*4+config_regbase);

	zpu_pokey_audctl = (unsigned char *)(0x18*4+config_regbase);

	zpu_pokey_skrest = (unsigned char *)(0x1a*4+config_regbase);
	zpu_pokey_serout = (unsigned char *)(0x1d*4+config_regbase);
	zpu_pokey_irqen = (unsigned char *)(0x1e*4+config_regbase);
	zpu_pokey_skctl = (unsigned char *)(0x1f*4+config_regbase);

	atari_nmien = (unsigned char *)(0xd40e + atari_regbase);
	atari_dlistl = (unsigned char *)(0xd402 + atari_regbase);
	atari_dlisth = (unsigned char *)(0xd403 + atari_regbase);
	atari_colbk = (unsigned char *)(0xd01a + atari_regbase);
	atari_colpf1 = (unsigned char *)(0xd017 + atari_regbase);
	atari_colpf2 = (unsigned char *)(0xd018 + atari_regbase);
	atari_colpf3 = (unsigned char *)(0xd019 + atari_regbase);
	atari_colpf0 = (unsigned char *)(0xd016 + atari_regbase);
	atari_prior = (unsigned char *)(0xd01b + atari_regbase);
	atari_random = (unsigned char *)(0xd20a + atari_regbase);
	atari_porta = (unsigned char *)(0xd300 + atari_regbase);
	atari_portb = (unsigned char *)(0xd301 + atari_regbase);
	atari_trig0 = (unsigned char *)(0xd010 + atari_regbase);
	atari_chbase = (unsigned char *)(0xd409 + atari_regbase);
	atari_chactl = (unsigned char *)(0xd401 + atari_regbase);
	atari_dmactl = (unsigned char *)(0xd400 + atari_regbase);
	atari_skctl = (unsigned char *)(0xd20f + atari_regbase);

	// command line is high
	*zpu_sio = 1;
	// no trigger pressed
	*atari_trig0 = 1;
}

