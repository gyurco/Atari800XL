#include "regs.h"
#include "memory.h"

int volatile * zpu_in1 = (int *)(0*4+config_regbase);
int volatile * zpu_in2 = (int *)(1*4+config_regbase);
int volatile * zpu_in3 = (int *)(2*4+config_regbase);
int volatile * zpu_in4 = (int *)(3*4+config_regbase);

int volatile * zpu_out1 = (int *)(4*4+config_regbase);
int volatile * zpu_out2 = (int *)(5*4+config_regbase);
int volatile * zpu_out3 = (int *)(6*4+config_regbase);
int volatile * zpu_out4 = (int *)(7*4+config_regbase);

int volatile * zpu_pause = (int *)(8*4+config_regbase);

int volatile * zpu_spi_data = (int *)(9*4+config_regbase);
int volatile * zpu_spi_state = (int *)(10*4+config_regbase);

int volatile * zpu_sio = (int *)(11*4+config_regbase);

int volatile * zpu_board = (int *)(12*4+config_regbase);

int volatile * zpu_spi_dma = (int *)(13*4+config_regbase);

unsigned char volatile * zpu_pokey_audf0 = (unsigned char *)(0x10*4+config_regbase);
unsigned char volatile * zpu_pokey_audc0 = (unsigned char *)(0x11*4+config_regbase);
unsigned char volatile * zpu_pokey_audf1 = (unsigned char *)(0x12*4+config_regbase);
unsigned char volatile * zpu_pokey_audc1 = (unsigned char *)(0x13*4+config_regbase);
unsigned char volatile * zpu_pokey_audf2 = (unsigned char *)(0x14*4+config_regbase);
unsigned char volatile * zpu_pokey_audc2 = (unsigned char *)(0x15*4+config_regbase);
unsigned char volatile * zpu_pokey_audf3 = (unsigned char *)(0x16*4+config_regbase);
unsigned char volatile * zpu_pokey_audc3 = (unsigned char *)(0x17*4+config_regbase);

unsigned char volatile * zpu_pokey_audctl = (unsigned char *)(0x18*4+config_regbase);

unsigned char volatile * zpu_pokey_skrest = (unsigned char *)(0x1a*4+config_regbase);
unsigned char volatile * zpu_pokey_serout = (unsigned char *)(0x1d*4+config_regbase);
unsigned char volatile * zpu_pokey_irqen = (unsigned char *)(0x1e*4+config_regbase);
unsigned char volatile * zpu_pokey_skctl = (unsigned char *)(0x1f*4+config_regbase);

unsigned char volatile * atari_nmien = (unsigned char *)(0xd40e + atari_regbase);
unsigned char volatile * atari_dlistl = (unsigned char *)(0xd402 + atari_regbase);
unsigned char volatile * atari_dlisth = (unsigned char *)(0xd403 + atari_regbase);
unsigned char volatile * atari_colbk = (unsigned char *)(0xd01a + atari_regbase);
unsigned char volatile * atari_colpf1 = (unsigned char *)(0xd017 + atari_regbase);
unsigned char volatile * atari_colpf2 = (unsigned char *)(0xd018 + atari_regbase);
unsigned char volatile * atari_colpf3 = (unsigned char *)(0xd019 + atari_regbase);
unsigned char volatile * atari_colpf0 = (unsigned char *)(0xd016 + atari_regbase);
unsigned char volatile * atari_prior = (unsigned char *)(0xd01b + atari_regbase);
unsigned char volatile * atari_random = (unsigned char *)(0xd20a + atari_regbase);
unsigned char volatile * atari_porta = (unsigned char *)(0xd300 + atari_regbase);
unsigned char volatile * atari_portb = (unsigned char *)(0xd301 + atari_regbase);
unsigned char volatile * atari_trig0 = (unsigned char *)(0xd010 + atari_regbase);
unsigned char volatile * atari_chbase = (unsigned char *)(0xd409 + atari_regbase);
unsigned char volatile * atari_chactl = (unsigned char *)(0xd401 + atari_regbase);
unsigned char volatile * atari_dmactl = (unsigned char *)(0xd400 + atari_regbase);
unsigned char volatile * atari_skctl = (unsigned char *)(0xd20f + atari_regbase);

