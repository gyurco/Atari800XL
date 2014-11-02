#ifndef regs_h
#define regs_h
#include "memory.h"

static const int screen_address = 11328;

#define zpu_in1 ((int volatile *)(0*4+config_regbase))
#define zpu_in2 ((int volatile *)(1*4+config_regbase))
#define zpu_in3 ((int volatile *)(2*4+config_regbase))
#define zpu_in4 ((int volatile *)(3*4+config_regbase))

#define zpu_out1 ((int volatile *)(4*4+config_regbase))
#define zpu_out2 ((int volatile *)(5*4+config_regbase))
#define zpu_out3 ((int volatile *)(6*4+config_regbase))
#define zpu_out4 ((int volatile *)(7*4+config_regbase))

#define zpu_pause ((int volatile *)(8*4+config_regbase))

#define zpu_spi_data ((int volatile *)(9*4+config_regbase))
#define zpu_spi_state ((int volatile *)(10*4+config_regbase))

#define zpu_sio ((int volatile *)(11*4+config_regbase))

#define zpu_board ((int volatile *)(12*4+config_regbase))

#define zpu_spi_dma ((int volatile *)(13*4+config_regbase))

#define zpu_pokey_audf0 ((unsigned char volatile *)(0x10*4+config_regbase))
#define zpu_pokey_audc0 ((unsigned char volatile *)(0x11*4+config_regbase))
#define zpu_pokey_audf1 ((unsigned char volatile *)(0x12*4+config_regbase))
#define zpu_pokey_audc1 ((unsigned char volatile *)(0x13*4+config_regbase))
#define zpu_pokey_audf2 ((unsigned char volatile *)(0x14*4+config_regbase))
#define zpu_pokey_audc2 ((unsigned char volatile *)(0x15*4+config_regbase))
#define zpu_pokey_audf3 ((unsigned char volatile *)(0x16*4+config_regbase))
#define zpu_pokey_audc3 ((unsigned char volatile *)(0x17*4+config_regbase))

#define zpu_pokey_audctl ((unsigned char volatile *)(0x18*4+config_regbase))

#define zpu_pokey_skrest ((unsigned char volatile *)(0x1a*4+config_regbase))
#define zpu_pokey_serout ((unsigned char volatile *)(0x1d*4+config_regbase))
#define zpu_pokey_irqen ((unsigned char volatile *)(0x1e*4+config_regbase))
#define zpu_pokey_skctl ((unsigned char volatile *)(0x1f*4+config_regbase))

#define atari_nmien ((unsigned char volatile *)(0xd40e + atari_regbase))
#define atari_dlistl ((unsigned char volatile *)(0xd402 + atari_regbase))
#define atari_dlisth ((unsigned char volatile *)(0xd403 + atari_regbase))

#define atari_porta ((unsigned char volatile *)(0xd300 + atari_regbase))
#define atari_portb ((unsigned char volatile *)(0xd301 + atari_regbase))
#define atari_trig0 ((unsigned char volatile *)(0xd010 + atari_regbase))
#define atari_chbase ((unsigned char volatile *)(0xd409 + atari_regbase))
#define atari_chactl ((unsigned char volatile *)(0xd401 + atari_regbase))
#define atari_dmactl ((unsigned char volatile *)(0xd400 + atari_regbase))

#ifdef FIRMWARE_5200
// 5200: GTIA and POKEY are on different addresses
#define atari_colbk ((unsigned char volatile *)(0xc01a + atari_regbase))
#define atari_colpf1 ((unsigned char volatile *)(0xc017 + atari_regbase))
#define atari_colpf2 ((unsigned char volatile *)(0xc018 + atari_regbase))
#define atari_colpf3 ((unsigned char volatile *)(0xc019 + atari_regbase))
#define atari_colpf0 ((unsigned char volatile *)(0xc016 + atari_regbase))
#define atari_prior ((unsigned char volatile *)(0xc01b + atari_regbase))
#define atari_consol ((unsigned char volatile *)(0xc01f + atari_regbase))

#define atari_skctl ((unsigned char volatile *)(0xe80f + atari_regbase))
#define atari_kbcode ((unsigned char volatile *)(0xe809 + atari_regbase))
#define atari_random ((unsigned char volatile *)(0xe80a + atari_regbase))
#define atari_pot0 ((unsigned char volatile *)(0xe800 + atari_regbase))
#define atari_pot1 ((unsigned char volatile *)(0xe801 + atari_regbase))
#define atari_potgo ((unsigned char volatile *)(0xe80b + atari_regbase))

#else

#define atari_colbk ((unsigned char volatile *)(0xd01a + atari_regbase))
#define atari_colpf1 ((unsigned char volatile *)(0xd017 + atari_regbase))
#define atari_colpf2 ((unsigned char volatile *)(0xd018 + atari_regbase))
#define atari_colpf3 ((unsigned char volatile *)(0xd019 + atari_regbase))
#define atari_colpf0 ((unsigned char volatile *)(0xd016 + atari_regbase))
#define atari_prior ((unsigned char volatile *)(0xd01b + atari_regbase))

#define atari_skctl ((unsigned char volatile *)(0xd20f + atari_regbase))
#define atari_kbcode ((unsigned char volatile *)(0xd209 + atari_regbase))
#define atari_random ((unsigned char volatile *)(0xd20a + atari_regbase))

#endif

#endif // regs_h
