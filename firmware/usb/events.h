void event_keyboard(uint8_t i, uint8_t buf[])
{
	int j;
	printf("Event keyboard:%d\n", i);
        for (j=0;j!=6;++j)
	{
		printf("Event keyboard:%d = %x\n", j, buf[j]);
	}
}
void event_mouse(uint8_t a, uint8_t b, uint8_t c)
{
	printf("Event mouse:%d %d %d\n",a,b,c);
}
void event_digital_joystick(uint8_t idx, uint8_t jmap)
{
	printf("Event joystick:%d %x\n", idx,jmap);
}
void event_analog_joystick(uint8_t idx, int8_t x, int8_t y)
{
	printf("Event analog joystick:%d %d %d\n", idx,x,y);
}

#define JOY_RIGHT       0x01
#define JOY_LEFT        0x02
#define JOY_DOWN        0x04
#define JOY_UP          0x08
#define JOY_BTN1        0x10
#define JOY_BTN2        0x20
#define JOY_BTN3        0x40
#define JOY_BTN4        0x80
#define JOY_MOVE        (JOY_RIGHT|JOY_LEFT|JOY_UP|JOY_DOWN)


