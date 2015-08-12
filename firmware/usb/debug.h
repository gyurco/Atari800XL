//#define hid_debugf(IN, ...) {};
//#define hidp_debugf(IN, ...) {};
//#define iprintf(IN, ...) {};

struct SimpleFile * usb_file;

void usb_log_init(struct SimpleFile * file)
{
	file_open_name("usb.log", &file);
	usb_file = file;
}

void usb_log(char * format, ...);

//#define hid_debugf usblog;
//#define hidp_debugf usb_log;
//#define iprintf usb_log;

