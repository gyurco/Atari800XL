#include "regs.h"

char native_porta;
char native_trig;

unsigned char volatile * atari_porta = &native_porta;
unsigned char volatile * atari_trig0 = &native_trig;

