#ifndef regs_h
#define regs_h

#define atari_regbase  0x10000
#define atari_regmirror  0x20000

extern int volatile * zpu_in1;
extern int volatile * zpu_in2;
extern int volatile * zpu_in3;
extern int volatile * zpu_in4;

extern int volatile * zpu_out1;
extern int volatile * zpu_out2;
extern int volatile * zpu_out3;
extern int volatile * zpu_out4;

extern int volatile * zpu_pause;
extern int volatile * zpu_spi_data;
extern int volatile * zpu_spi_state;
extern int volatile * zpu_sio;
extern int volatile * zpu_board;

extern int volatile * zpu_spi_dma;
 
extern unsigned char volatile * zpu_pokey_audf0;
extern unsigned char volatile * zpu_pokey_audc0;
extern unsigned char volatile * zpu_pokey_audf1;
extern unsigned char volatile * zpu_pokey_audc1;
extern unsigned char volatile * zpu_pokey_audf2;
extern unsigned char volatile * zpu_pokey_audc2;
extern unsigned char volatile * zpu_pokey_audf3;
extern unsigned char volatile * zpu_pokey_audc3;
 
extern unsigned char volatile * zpu_pokey_audctl;
 
extern unsigned char volatile * zpu_pokey_skrest;
extern unsigned char volatile * zpu_pokey_serout;
extern unsigned char volatile * zpu_pokey_irqen;
extern unsigned char volatile * zpu_pokey_skctl;

extern unsigned char volatile * atari_nmien;
extern unsigned char volatile * atari_dlistl;
extern unsigned char volatile * atari_dlisth;
extern unsigned char volatile * atari_colbk;
extern unsigned char volatile * atari_colpf1;
extern unsigned char volatile * atari_colpf2;
extern unsigned char volatile * atari_colpf3;
extern unsigned char volatile * atari_colpf0;
extern unsigned char volatile * atari_prior;
extern unsigned char volatile * atari_random;
extern unsigned char volatile * atari_porta;
extern unsigned char volatile * atari_portb;
extern unsigned char volatile * atari_trig0;
extern unsigned char volatile * atari_chbase;
extern unsigned char volatile * atari_chactl;
extern unsigned char volatile * atari_dmactl;
extern unsigned char volatile * atari_skctl;
extern unsigned char volatile * atari_kbcode;

#endif // regs_h
