/*
 * OHS900 register declarations and HCD data structures
 *
 * Copyright (C) 2005 Steve Fielding
 * Copyright (C) 2004 Psion Teklogix
 * Copyright (C) 2004 David Brownell
 */

// ----------------------- FIXME using direct memory access
// base address of OHS900 MWW TODO!!!
//#define OHS900_BASE 0x80900c00

char usbhostslave[0x100];

/*
 * OHS900 has transfer registers, and control registers.  In host/master
 * mode one set of registers is used; in peripheral/slave mode, another.
 */


/* TRANSFER REGISTERS
 */
#define OHS900_HOST_TX_CTLREG	0x00 
#	define OHS900_HCTLMASK_TRANS_REQ		0x01 
#	define OHS900_HCTLMASK_SOF_SYNC		0x02 
#	define OHS900_HCTLMASK_PREAMBLE_EN	0x04 
#	define OHS900_HCTLMASK_ISO_EN		0x08 


#define OHS900_HRXSTATREG	0x0a	/* read */ 
#	define OHS900_STATMASK_CRC_ERROR		0x01 
#	define OHS900_STATMASK_BS_ERROR		0x02 
#	define OHS900_STATMASK_RX_OVF		0x04 
#	define OHS900_STATMASK_RX_TMOUT		0x08 
#	define OHS900_STATMASK_NAK_RXED		0x10 
#	define OHS900_STATMASK_STALL_RXED	0x20 
#	define OHS900_STATMASK_ACK_RXED		0x40 
#	define OHS900_STATMASK_DATA_SEQ		0x80 

#define OHS900_TXTRANSTYPEREG		0x01	/* write */ 
#	define	OHS900_SETUP	0x00 
#	define	OHS900_IN	0x01 
#	define	OHS900_OUT_DATA0	0x02 
#	define	OHS900_OUT_DATA1	0x03 

#define OHS900_TXADDRREG	0x04	
#define OHS900_TXENDPREG	0x05	

/* CONTROL REGISTERS:  
 */
#define OHS900_SOFENREG		0x03 
#	define OHS900_MASK_SOF_ENA	0x01 

#define OHS900_TXLINECTLREG 0x02 
#	define OHS900_TXLCTL_MASK_FORCE	0x4 
#	define OHS900_TXLCTL_MASK_LINE_CTRL_BITS 0x7
#		define OHS900_TXLCTL_MASK_NORMAL	0x00 
#		define OHS900_TXLCTL_MASK_SE0	0x04	
#		define OHS900_TXLCTL_MASK_FS_J	0x06    
#		define OHS900_TXLCTL_MASK_FS_K	0x05	
#	define OHS900_TXLCTL_MASK_LSPD	0x00 
#	define OHS900_TXLCTL_MASK_FSPD	0x18 
#	define OHS900_TXLCTL_MASK_FS_POL	0x08 
#	define OHS900_TXLCTL_MASK_FS_RATE 0x10 


#define OHS900_IRQ_ENABLE	0x09             
#	define OHS900_INTMASK_TRANS_DONE	0x01   
#	define OHS900_INTMASK_SOFINTR	0x08   
#	define OHS900_INTMASK_INSRMV	0x04   	
#	define OHS900_INTMASK_RESUME_DET	0x02   
		  
#define OHS900_RXCONNSTATEREG 0x0e
#define   OHS900_DISCONNECT_STATE 0x00
#define   OHS900_LS_CONN_STATE 0x01
#define   OHS900_FS_CONN_STATE 0x02

#define OHS900_SLAVE_ADDRESS		0x54 



#define OHS900_IRQ_STATUS	0x08	/* write to ack */ 
#define OHS900_HWREVREG		0xe1	/* read */ 

#define OHS900_SOFTMRREG		0x0F 



#define OHS900_HOSTSLAVECTLREG 			0xe0 
#	define OHS900_HSCTLREG_HOST_EN_MASK	0x01 
#	define OHS900_HSCTLREG_RESET_CORE	0x02 



#define OHS900_HS_CTL_INIT OHS900_HSCTLREG_HOST_EN_MASK 

/* 64-byte FIFO control and status
 */
#define H_MAXPACKET	64		/* bytes in fifos */

#define OHS900_HOST_TXFIFO_DATA	0x30 
#define OHS900_TXFIFOCNTMSBREG	0x32 
#define OHS900_TXFIFOCNTLSBREG	0x33
#define OHS900_TXFIFOCONTROLREG	0x34
#define OHS900_HOST_RXFIFO_DATA	0x20 
#define OHS900_RXFIFOCNTMSBREG	0x22 
#define OHS900_RXFIFOCNTLSBREG	0x23
#define OHS900_RXFIFOCONTROLREG	0x24
#define		OHS900_FIFO_FORCE_EMPTY 0x01


#define OHS900_IO_EXTENT 0x100

