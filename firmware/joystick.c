#include "joystick.h"

#include "regs.h"

//#include <stdio.h>

void joystick_poll(struct joystick_status * status)
{
	status->x_ = 0;
	status->y_ = 0;
	status->fire_ = 0;

	unsigned char porta = *atari_porta;

	status->y_ = !(porta&0x2) -((unsigned int)!(porta&0x1));
	status->x_ = !(porta&0x8) -((unsigned int)!(porta&0x4));
	status->fire_ = !(1&*atari_trig0);

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
			if (status->x_ == 0 && status->y_ == 0 && status->fire_ == 0) return;
			break;
		case WAIT_FIRE:
			if (status->fire_ == 1) return;
			break;
		case WAIT_EITHER:
			if (status->fire_ == 1) return;
			// fall through
		case WAIT_MOVE:
			if (status->x_ !=0 || status->y_ != 0) return;
			break;
		}
	}
}

