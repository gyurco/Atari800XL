#pragma once

struct joystick_status
{
	char x_;
	char y_;
	char fire_;
};

enum JoyWait {WAIT_QUIET, WAIT_FIRE, WAIT_MOVE, WAIT_EITHER};

void joystick_poll(struct joystick_status * status);
void joystick_wait(struct joystick_status * status, enum JoyWait waitFor);

