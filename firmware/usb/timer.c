#include "timer.h"

// this is a 32 bit counter which overflows after 2^32 milliseconds
// -> after 46 days

void wait_us(int unsigned num);

void timer_init() {
	// TODO - set zpu to 0...
}

msec_t timer_get_msec() {
	return 0; // TODO - read from ZPU
}

void timer_delay_msec(msec_t t) {
	int y = t;
	wait_us(y*1000);
}
