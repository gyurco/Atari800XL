#include "joystick.h"

#include "regs.h"
//#include "io.h"

//#include <stdio.h>

#ifdef USB
#include "usb.h"
#endif

#ifdef USB
extern struct usb_host usb_porta;
#endif
#ifdef USB2
extern struct usb_host usb_portb;
#endif

int ps2Pressed;

static unsigned char ps2ascii[] = 
{
	0x1C,//'A',
	0x32,//'B',
	0x21,//'C',
	0x23,//'D',
	0x24,//'E',
	0x2B,//'F',
	0x34,//'G',
	0x33,//'H',
	0x43,//'I',
	0x3B,//'J',
	0x42,//'K',
	0x4B,//'L',
	0x3A,//'M',
	0x31,//'N',
	0x44,//'O',
	0x4D,//'P',
	0x15,//'Q',
	0x2D,//'R',
	0x1B,//'S',
	0x2C,//'T',
	0x3C,//'U',
	0x2A,//'V',
	0x1D,//'W',
	0x22,//'X',
	0x35,//'Y',
	0x1A,//'Z'
};

static unsigned char ps2asciinum[] = 
{
	0x45,//'0',
	0x16,//'1',
	0x1E,//'2',
	0x26,//'3',
	0x25,//'4',
	0x2E,//'5',
	0x36,//'6',
	0x3D,//'7',
	0x3E,//'8',
	0x46,//'9',
};

int decodeKey(int ps2)
{
	int i;
	for (i='A';i<='Z';++i)
	{
		if (ps2ascii[i-'A']==ps2)
			return i;
	}
	for (i='0';i<='9';++i)
	{
		if (ps2asciinum[i-'0']==ps2)
			return i;
	}
	if (ps2 == 0x66)
	{
		return -1;
	}
	return 0;
}

void joystick_poll(struct joystick_status * status)
{
	status->x_ = 0;
	status->y_ = 0;
	status->fire_ = 0;
	status->escape_ = 0;
	status->keyPressed_ = decodeKey(ps2Pressed);

#ifdef USB
	usb_poll(&usb_porta);
#endif
#ifdef USB2
	usb_poll(&usb_portb);
#endif

	unsigned char porta = *atari_porta;
	porta = (porta>>4) & (porta);

	int controls = get_controls();

	status->y_ = !(porta&0x2) -((unsigned int)!(porta&0x1));
	status->x_ = !(porta&0x8) -((unsigned int)!(porta&0x4));
	status->fire_ = !(1&*atari_trig0&*atari_trig1);

	if (controls!=0)
	{
		status->y_ = !!(controls&0x2) -((unsigned int)!!(controls&0x1));
		status->x_ = !!(controls&0x8) -((unsigned int)!!(controls&0x4));
		status->fire_ = !!(controls&0x10);
		status->escape_ = !!(controls&0x20);
	}

	//if (porta != 0xff)
	//printf("%02x %x %x %x\n",porta,status->x_,status->y_,status->fire_);
/*
	if (0==(porta&0x2)) // down
	{
		status->y_ =1;
	}
	else if (0==(porta&0x1)) // up
	{
		status->y_ =-1;
	}
	if (0==(porta&0x8)) // right
	{
		status->x_ = 1;
	}
	else if (0==(porta&0x4)) // left
	{
		status->x_ = -1;
	}
	if (0==(1&*atari_trig0)) // fire
	{
		status->fire_ = 1;
	}
*/
}

void joystick_wait(struct joystick_status * status, enum JoyWait waitFor)
{
	while (1)
	{
		joystick_poll(status);
		switch (waitFor)
		{
		case WAIT_QUIET:
			if (status->x_ == 0 && status->y_ == 0 && status->fire_ == 0 && status->keyPressed_ == 0) return;
			break;
		case WAIT_FIRE:
			if (status->fire_ == 1 || status->escape_==1) return;
			break;
		case WAIT_EITHER:
			if (status->fire_ == 1) return;
			// fall through
		case WAIT_MOVE:
			if (status->x_ !=0 || status->y_ != 0 || status->escape_==1 || status->keyPressed_ !=0) return;
			break;
		}
	}
}

