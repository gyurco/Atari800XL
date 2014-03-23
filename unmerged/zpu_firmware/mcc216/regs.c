#ifndef regs_h
#define regs_h

#define regbase	0x40000
int volatile * zpu_config = (int *)(0*4+regbase);
int volatile * zpu_pause = (int *)(1*4+regbase);
int volatile * zpu_switches = (int *)(2*4+regbase);
int volatile * zpu_key = (int *)(3*4+regbase);
int volatile * zpu_ledg = (int *)(4*4+regbase);
int volatile * zpu_ledr = (int *)(5*4+regbase);
int volatile * zpu_spi_data = (int *)(6*4+regbase);
int volatile * zpu_spi_state = (int *)(7*4+regbase);
int volatile * zpu_sio = (int *)(8*4+regbase);
int volatile * zpu_board = (int *)(9*4+regbase);
int volatile * zpu_hex = (int *)(10*4+regbase);

unsigned char volatile * zpu_pokey_audf0 = (unsigned char *)(0x10*4+regbase);
unsigned char volatile * zpu_pokey_audc0 = (unsigned char *)(0x11*4+regbase);
unsigned char volatile * zpu_pokey_audf1 = (unsigned char *)(0x12*4+regbase);
unsigned char volatile * zpu_pokey_audc1 = (unsigned char *)(0x13*4+regbase);
unsigned char volatile * zpu_pokey_audf2 = (unsigned char *)(0x14*4+regbase);
unsigned char volatile * zpu_pokey_audc2 = (unsigned char *)(0x15*4+regbase);
unsigned char volatile * zpu_pokey_audf3 = (unsigned char *)(0x16*4+regbase);
unsigned char volatile * zpu_pokey_audc3 = (unsigned char *)(0x17*4+regbase);

unsigned char volatile * zpu_pokey_audctl = (unsigned char *)(0x18*4+regbase);

unsigned char volatile * zpu_pokey_skrest = (unsigned char *)(0x1a*4+regbase);
unsigned char volatile * zpu_pokey_serout = (unsigned char *)(0x1d*4+regbase);
unsigned char volatile * zpu_pokey_irqen = (unsigned char *)(0x1e*4+regbase);
unsigned char volatile * zpu_pokey_skctl = (unsigned char *)(0x1f*4+regbase);

unsigned char volatile * atari_nmien = (unsigned char *)(0xd40e + 0x10000);
unsigned char volatile * atari_dlistl = (unsigned char *)(0xd402 + 0x10000);
unsigned char volatile * atari_dlisth = (unsigned char *)(0xd403 + 0x10000);
unsigned char volatile * atari_colbk = (unsigned char *)(0xd01a + 0x10000);
unsigned char volatile * atari_colpf1 = (unsigned char *)(0xd017 + 0x10000);
unsigned char volatile * atari_colpf2 = (unsigned char *)(0xd018 + 0x10000);
unsigned char volatile * atari_prior = (unsigned char *)(0xd01b + 0x10000);
unsigned char volatile * atari_random = (unsigned char *)(0xd20a + 0x10000);
unsigned char volatile * atari_porta = (unsigned char *)(0xd300 + 0x10000);
unsigned char volatile * atari_portb = (unsigned char *)(0xd301 + 0x10000);
unsigned char volatile * atari_trig0 = (unsigned char *)(0xd010 + 0x10000);
unsigned char volatile * atari_chbase = (unsigned char *)(0xd409 + 0x10000);
unsigned char volatile * atari_chactl = (unsigned char *)(0xd401 + 0x10000);
unsigned char volatile * atari_dmactl = (unsigned char *)(0xd400 + 0x10000);
unsigned char volatile * atari_skctl = (unsigned char *)(0xd20f + 0x10000);

#endif // regs_h
