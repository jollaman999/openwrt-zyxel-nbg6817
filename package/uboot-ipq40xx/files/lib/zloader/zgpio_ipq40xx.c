/*****************************************************************************
 * Copyright (C) ZyXEL Communications, Corp.
 * All Rights Reserved.
 *
 * ZyXEL Confidential; Need to Know only.
 * Protected as an unpublished work.
 *
 * The computer program listings, specifications and documentation
 * herein are the property of ZyXEL Communications, Corp. and
 * shall not be reproduced, copied, disclosed, or used in whole or
 * in part for any reason without the prior express written permission of
 * ZyXEL Communications, Corp.
 *****************************************************************************/
/*****************************************************************************
 * Program: IPQ680x GPIO driver for zloader
 *  Author: Chang-Hsing Lee.(changhsing.lee@zyxel.com.tw), 2014/09/04
 *****************************************************************************/

#include <asm/arch-ipq40xx/iomap.h>
#include <asm/arch-qcom-common/gpio.h>
#include <asm/io.h>

#define DEFAULT_DRIVE_STRENGTH      GPIO_8MA
#define ZPIO_MAX_NUM                64

int zpio_cfg(int pio, int dir)
{
    if (pio >= ZPIO_MAX_NUM) {
        return -1;
    }
    if (dir == ZGPIO_CONFIG_OUTPUT ) {
        /* configure GPIO as output pin */
        gpio_tlmm_config(pio, 0, GPIO_OUTPUT, GPIO_PULL_UP, DEFAULT_DRIVE_STRENGTH, GPIO_OE_ENABLE, GPIO_VM_ENABLE, GPIO_OD_DISABLE, GPIO_PULL_RES2);
    } else if (dir == ZGPIO_CONFIG_INPUT) {
        /* configure GPIO as input pin */
        gpio_tlmm_config(pio, 0, GPIO_INPUT, GPIO_PULL_UP, DEFAULT_DRIVE_STRENGTH, GPIO_OE_DISABLE,  GPIO_VM_ENABLE, GPIO_OD_DISABLE, GPIO_PULL_RES2);
    }
    return 0;
}

/* set GPIO state */
int zpio_set(int pio, int level)
{
    unsigned int *addr;
    if (pio >= ZPIO_MAX_NUM) {
        return -1;
    }
    addr = (unsigned int *)GPIO_IN_OUT_ADDR(pio);
    writel((level==ZGPIO_LEVEL_HIGH)?3:0, addr);

    return 0;
}

/* get GPIO status */
int zpio_get(int pio, int *level)
{
    unsigned int *addr;
    if (pio >= ZPIO_MAX_NUM) {
        return -1;
    }
    addr = (unsigned int *)GPIO_IN_OUT_ADDR(pio);
    *level = readl(addr)&3?ZGPIO_LEVEL_HIGH:ZGPIO_LEVEL_LOW;
    return 0;
}

/* number of GPIO pins */
int zpio_max_num(void)
{
    return ZPIO_MAX_NUM;
}

/* dump GPIO related registers */
void zpio_dump_regs(void)
{
    /* dump GPIO related registers */
    int i;
    for (i=0; i<ZPIO_MAX_NUM; i++) {
        printf("GPIO_CFG%2d(0x%08X)=0x%08X, GPIO_IN_OUT%2d(0x%08X)=0x%08X\n",
               i, GPIO_CONFIG_ADDR(i), readl(GPIO_CONFIG_ADDR(i)), 
               i, GPIO_IN_OUT_ADDR(i), readl(GPIO_IN_OUT_ADDR(i)));
    }
}


