/*
 * (C) Copyright 2007
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */
#include <config.h>
#include <common.h>
#include <asm/hardware.h>
#include <asm/arch/bsp.h>

#if defined(CONFIG_HARD_I2C) || defined(CONFIG_SOFT_I2C)
#define MAX_I2C_RETRYS	    10
#define I2C_DELAY	    1000	/* Should be at least the # of MHz of Tclk */

#define I2C_ADDR                        (I2C_BASEADDR + 0x00)
#define I2C_DATA                        (I2C_BASEADDR + 0x04)
#define I2C_CNTR                        (I2C_BASEADDR + 0x08)
#define I2C_STAT                        (I2C_BASEADDR + 0x0c)
#define I2C_CCRFS                       (I2C_BASEADDR + 0x0c)
#define I2C_XADDR                       (I2C_BASEADDR + 0x10)
#define I2C_CCRH                        (I2C_BASEADDR + 0x14)
#define I2C_SOFT_RESET                  (I2C_BASEADDR + 0x1c)

/* CNTR - Control register bits */
#define I2C_IEN				(1<<7)
#define I2C_ENAB			(1<<6)
#define I2C_STA				(1<<5)
#define I2C_STP				(1<<4)
#define I2C_IFLG			(1<<3)
#define I2C_AAK				(1<<2)

/* STAT - Status codes */
#define I2C_BUS_ERROR			0x00	/* Bus error in master mode only */
#define I2C_START_TRANSMIT		0x08	/* Start condition transmitted */
#define I2C_REPEAT_START_TRANSMIT	0x10	/* Repeated Start condition transmited */
#define I2C_ADDRESS_W_ACK		0x18	/* Address + Write bit transmitted, ACK received */
#define I2C_ADDRESS_W_NACK		0x20	/* Address + Write bit transmitted, NACK received */
#define I2C_DATA_TRANSMIT_ACK		0x28	/* Data byte transmitted in master mode , ACK received */
#define I2C_DATA_TRANSMIT_NACK		0x30	/* Data byte transmitted in master mode , NACK received */
#define I2C_ARBIT_LOST			0x38	/* Arbitration lost in address or data byte */
#define I2C_ADDRESS_R_ACK		0x40	/* Address + Read bit transmitted, ACK received  */
#define I2C_ADDRESS_R_NACK		0x48	/* Address + Read bit transmitted, NACK received  */
#define I2C_DATA_RECEIVE_ACK		0x50	/* Data byte received in master mode, ACK transmitted  */
#define I2C_DATA_RECEIVE_NACK		0x58	/* Data byte received in master mode, NACK transmitted*/
#define I2C_ARBIT_LOST_ADDRESS		0x68	/* Arbitration lost in address  */
#define I2C_GENERAL_CALL		0x70	/* General Call, ACK transmitted */
#define I2C_NO_RELEVANT_INFO		0xF8	/* No relevant status information, IFLF=0 */

#define I2C_READ_REG(reg)	        *(volatile u32*)(reg)
#define I2C_WRITE_REG(reg, val)	        *(volatile u32*)(reg) = val
#define RESET_REG_BITS(reg, val)        I2C_WRITE_REG(reg, I2C_READ_REG(reg) & ~(val))

#undef	DEBUG_I2C
//#define DEBUG_I2C

#ifdef DEBUG_I2C
#define DP(x) x
#else
#define DP(x)
#endif

/* Assuming that there is only one master on the bus (us) */

void i2c_init (int speed, int slaveaddr)
{
	unsigned int n, m, freq, margin, power;
	unsigned int actualN = 0, actualM = 0;
	unsigned int control, status;
	unsigned int minMargin = 0xffffffff;
	unsigned int tclk = CONFIG_SYS_TCLK;
	unsigned int i2cFreq = speed;	/* 100000 max. Fast mode not supported */

	DP (puts ("i2c_init\n"));

	for (n = 0; n < 8; n++) {
		for (m = 0; m < 16; m++) {
			power = 1 << n;	/* power = 2^(n) */
			freq = tclk / (10 * (m + 1) * power);
			if (i2cFreq > freq)
				margin = i2cFreq - freq;
			else
				margin = freq - i2cFreq;
			if (margin < minMargin) {
				minMargin = margin;
				actualN = n;
				actualM = m;
			}
		}
	}

	DP (puts ("setup i2c bus\n"));

	/* Setup bus */
        I2C_WRITE_REG(I2C_SOFT_RESET, 0);

	DP (puts ("udelay...\n"));

	udelay (I2C_DELAY);

	DP (puts ("set baudrate\n"));

	I2C_WRITE_REG(I2C_STAT, (actualM << 3) | actualN);
	I2C_WRITE_REG(I2C_CNTR, I2C_AAK | I2C_ENAB);

	udelay (I2C_DELAY * 10);

	DP (puts ("read control, baudrate\n"));

	status = I2C_READ_REG(I2C_STAT);
	control = I2C_READ_REG(I2C_CNTR);
}

static uchar i2c_start (void)
{
	unsigned int control, status;
	int count = 0;

	DP (puts ("i2c_start\n"));

	/* Set the start bit */

	control = I2C_READ_REG(I2C_CNTR);
	control |= I2C_STA;	/* generate the I2C_START_BIT */
	I2C_WRITE_REG(I2C_CNTR, control);

	status = I2C_READ_REG(I2C_STAT);

	count = 0;
	while ((status & 0xff) != I2C_START_TRANSMIT) {
		udelay (I2C_DELAY);
		if (count > 20) {
			I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/*stop */
			return (status);
		}
		status = I2C_READ_REG(I2C_STAT);
		count++;
	}

	return (0);
}

static uchar i2c_select_device (uchar dev_addr, uchar read, int ten_bit)
{
	unsigned int status, data, bits = 7;
	int count = 0;

	DP (puts ("i2c_select_device\n"));

	/* Output slave address */

	if (ten_bit) {
		bits = 10;
	}

	data = (dev_addr << 1);
	/* set the read bit */
	data |= read;
	I2C_WRITE_REG(I2C_DATA, data);
	/* assert the address */
	RESET_REG_BITS (I2C_CNTR, I2C_IFLG);

	udelay (I2C_DELAY);

	status = I2C_READ_REG(I2C_STAT);
	count = 0;
	while (((status & 0xff) != I2C_ADDRESS_R_ACK) && ((status & 0xff) != I2C_ADDRESS_W_ACK)) {
		udelay (I2C_DELAY);
		if (count > 20) {
			I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/*stop */
			return (status);
		}
		status = I2C_READ_REG(I2C_STAT);
		count++;
	}

	if (bits == 10) {
		printf ("10 bit I2C addressing not yet implemented\n");
		return (0xff);
	}

	return (0);
}

static uchar i2c_get_data (uchar * return_data, int len)
{

	unsigned int data, status = 0;
	int count = 0;

	DP (puts ("i2c_get_data\n"));

	while (len) {

		/* Get and return the data */

		RESET_REG_BITS (I2C_CNTR, I2C_IFLG);

		udelay (I2C_DELAY * 5);

		status = I2C_READ_REG(I2C_STAT);
		count++;
		while ((status & 0xff) != I2C_DATA_RECEIVE_ACK) {
			udelay (I2C_DELAY);
			if (count > 2) {
				I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/*stop */
				return 0;
			}
			status = I2C_READ_REG(I2C_STAT);
			count++;
		}
		data = I2C_READ_REG(I2C_DATA);
		len--;
		*return_data = (uchar) data;
		return_data++;
	}
	RESET_REG_BITS (I2C_CNTR, I2C_AAK | I2C_IFLG);
	while ((status & 0xff) != I2C_DATA_RECEIVE_NACK) {
		udelay (I2C_DELAY);
		if (count > 200) {
			I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/*stop */
			return (status);
		}
		status = I2C_READ_REG(I2C_STAT);
		count++;
	}
	I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/* stop */

	return (0);
}

static uchar i2c_write_data (unsigned int *data, int len)
{
	unsigned int status;
	int count = 0;
	unsigned int temp;
	unsigned int *temp_ptr = data;

	DP (puts ("i2c_write_data\n"));

	while (len) {
		temp = (unsigned int) (*temp_ptr);
		I2C_WRITE_REG(I2C_DATA, temp);
		RESET_REG_BITS (I2C_CNTR, I2C_IFLG);

		udelay (I2C_DELAY);

		status = I2C_READ_REG(I2C_STAT);
		count++;
		while ((status & 0xff) != I2C_DATA_TRANSMIT_ACK) {
			udelay (I2C_DELAY);
			if (count > 20) {
				I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/*stop */
				return (status);
			}
			status = I2C_READ_REG(I2C_STAT);
			count++;
		}
		len--;
		temp_ptr++;
	}

/* Can't have the write issuing a stop command */
/* it's wrong to have a stop bit in read stream or write stream */
/* since we don't know if it's really the end of the command */
/* or whether we have just send the device address + offset */
/* we will push issuing the stop command off to the original */
/* calling function */
	/* set the interrupt bit in the control register */
	I2C_WRITE_REG(I2C_CNTR, I2C_IFLG);
	udelay (I2C_DELAY * 10);
	return (0);
}

/* created this function to get the i2c_write() */
/* function working properly. */
/* function to write bytes out on the i2c bus */
/* this is identical to the function i2c_write_data() */
/* except that it requires a buffer that is an */
/* unsigned character array.  You can't use */
/* i2c_write_data() to send an array of unsigned characters */
/* since the byte of interest ends up on the wrong end of the bus */
/* aah, the joys of big endian versus little endian! */
/* */
/* returns 0 = success */
/*         anything other than zero is failure */
static uchar i2c_write_byte (unsigned char *data, int len)
{
	unsigned int status;
	int count = 0;
	unsigned int temp;
	unsigned char *temp_ptr = data;

	DP (puts ("i2c_write_byte\n"));

	while (len) {
		/* Set and assert the data */
		temp = *temp_ptr;
		I2C_WRITE_REG(I2C_DATA, temp);
		RESET_REG_BITS (I2C_CNTR, I2C_IFLG);

		udelay (I2C_DELAY*2);

		status = I2C_READ_REG(I2C_STAT);
		count++;
		while ((status & 0xff) != I2C_DATA_TRANSMIT_ACK) {
			udelay (I2C_DELAY*2);
			if (count > 20) {
				I2C_WRITE_REG(I2C_CNTR, I2C_STP);	/*stop */
				return (status);
			}
			status = I2C_READ_REG(I2C_STAT);
			count++;
		}
		len--;
		temp_ptr++;
	}
/* Can't have the write issuing a stop command */
/* it's wrong to have a stop bit in read stream or write stream */
/* since we don't know if it's really the end of the command */
/* or whether we have just send the device address + offset */
/* we will push issuing the stop command off to the original */
/* calling function */
/*	I2C_WRITE_REG(I2C_CNTR, I2C_IFLG | I2C_STP);
	I2C_WRITE_REG(I2C_CNTR, I2C_STP); */
	/* set the interrupt bit in the control register */
	I2C_WRITE_REG(I2C_CNTR, I2C_IFLG);
	udelay (I2C_DELAY * 10);

	return (0);
}

static uchar
i2c_set_dev_offset (uchar dev_addr, unsigned int offset, int ten_bit,
		    int alen)
{
	uchar status;
	unsigned int table[2];

/* initialize the table of address offset bytes */
/* utilized for 2 byte address offsets */
/* NOTE: the order is high byte first! */
	table[1] = offset & 0xff;	/* low byte */
	table[0] = offset / 0x100;	/* high byte */

	DP (puts ("i2c_set_dev_offset\n"));

	status = i2c_select_device (dev_addr, 0, ten_bit);
	if (status) {
#ifdef DEBUG_I2C
		printf ("Failed to select device setting offset: 0x%02x\n",
			status);
#endif
		return status;
	}
/* check the address offset length */
	if (alen == 0)
		/* no address offset */
		return (0);
	else if (alen == 1) {
		/* 1 byte address offset */
		status = i2c_write_data (&offset, 1);
		if (status) {
#ifdef DEBUG_I2C
			printf ("Failed to write data: 0x%02x\n", status);
#endif
			return status;
		}
	} else if (alen == 2) {
		/* 2 bytes address offset */
		status = i2c_write_data (table, 2);
		if (status) {
#ifdef DEBUG_I2C
			printf ("Failed to write data: 0x%02x\n", status);
#endif
			return status;
		}
	} else {
		/* address offset unknown or not supported */
		printf ("Address length offset %d is not supported\n", alen);
		return 1;
	}
	return 0;		/* sucessful completion */
}

uchar
i2c_read (uchar dev_addr, unsigned int offset, int alen, uchar * data,
	  int len)
{
	uchar status = 0;
	unsigned int i2cFreq = CONFIG_SYS_I2C_SPEED;

	DP (puts ("i2c_read\n"));

	i2c_init (i2cFreq, 0);	/* set the i2c frequency */

	status = i2c_start ();

	if (status) {
#ifdef DEBUG_I2C
		printf ("Transaction start failed: 0x%02x\n", status);
#endif
		return status;
	}

	status = i2c_set_dev_offset (dev_addr, offset, 0, alen);	/* send the slave address + offset */
	if (status) {
#ifdef DEBUG_I2C
		printf ("Failed to set slave address & offset: 0x%02x\n",
			status);
#endif
		return status;
	}

	i2c_init (i2cFreq, 0);	/* set the i2c frequency again */

	status = i2c_start ();
	if (status) {
#ifdef DEBUG_I2C
		printf ("Transaction restart failed: 0x%02x\n", status);
#endif
		return status;
	}

	status = i2c_select_device (dev_addr, 1, 0);	/* send the slave address */
	if (status) {
#ifdef DEBUG_I2C
		printf ("Address not acknowledged: 0x%02x\n", status);
#endif
		return status;
	}

	status = i2c_get_data (data, len);
	if (status) {
#ifdef DEBUG_I2C
		printf ("Data not recieved: 0x%02x\n", status);
#endif
		return status;
	}

	return 0;
}

/* Function to set the I2C stop bit */
void i2c_stop (void)
{
	I2C_WRITE_REG(I2C_CNTR, (0x1 << 4));
}

/* I2C write function */
/* dev_addr = device address */
/* offset = address offset */
/* alen = length in bytes of the address offset */
/* data = pointer to buffer to read data into */
/* len = # of bytes to read */
/* */
/* returns 0 = succesful */
/*         anything but zero is failure */
uchar
i2c_write (uchar dev_addr, unsigned int offset, int alen, uchar * data,
	   int len)
{
	uchar status = 0;
	unsigned int i2cFreq = CONFIG_SYS_I2C_SPEED;

	DP (puts ("i2c_write\n"));

	i2c_init (i2cFreq, 0);	/* set the i2c frequency */

	status = i2c_start ();	/* send a start bit */

	if (status) {
#ifdef DEBUG_I2C
		printf ("Transaction start failed: 0x%02x\n", status);
#endif
		return status;
	}

	status = i2c_set_dev_offset (dev_addr, offset, 0, alen);	/* send the slave address + offset */
	if (status) {
#ifdef DEBUG_I2C
		printf ("Failed to set slave address & offset: 0x%02x\n",
			status);
#endif
		return status;
	}


	status = i2c_write_byte (data, len);	/* write the data */
	if (status) {
#ifdef DEBUG_I2C
		printf ("Data not written: 0x%02x\n", status);
#endif
		return status;
	}
	/* issue a stop bit */
	i2c_stop ();
	return 0;
}

/* function to determine if an I2C device is present */
/* chip = device address of chip to check for */
/* */
/* returns 0 = sucessful, the device exists */
/*         anything other than zero is failure, no device */
int i2c_probe (uchar chip)
{

	/* We are just looking for an <ACK> back. */
	/* To see if the device/chip is there */

#ifdef DEBUG_I2C
	unsigned int i2c_status;
#endif
	uchar status = 0;
	unsigned int i2cFreq = CONFIG_SYS_I2C_SPEED;

	DP (puts ("i2c_probe\n"));

	i2c_init (i2cFreq, 0);	/* set the i2c frequency */

	status = i2c_start ();	/* send a start bit */

	if (status) {
#ifdef DEBUG_I2C
		printf ("Transaction start failed: 0x%02x\n", status);
#endif
		return (int) status;
	}

	status = i2c_set_dev_offset (chip, 0, 0, 0);	/* send the slave address + no offset */
	if (status) {
#ifdef DEBUG_I2C
		printf ("Failed to set slave address: 0x%02x\n", status);
#endif
		return (int) status;
	}
#ifdef DEBUG_I2C
	i2c_status = I2C_READ_REG(I2C_STAT);
	printf ("address %#x returned %#x\n", chip, i2c_status);
#endif
	/* issue a stop bit */
	i2c_stop ();
	return 0;		/* successful completion */
}

#endif
