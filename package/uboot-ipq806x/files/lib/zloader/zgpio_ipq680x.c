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

#include <asm/arch-ipq806x/iomap.h>
#include <asm/arch-ipq806x/gpio.h>
#include <asm/io.h>

#define DEFAULT_DRIVE_STRENGTH      GPIO_8MA
#define ZPIO_MAX_NUM                69

int zpio_cfg(int pio, int dir)
{
    if (pio >= ZPIO_MAX_NUM) {
        return -1;
    }
    if (dir == ZGPIO_CONFIG_OUTPUT ) {
        /* configure GPIO as output pin */
#if defined(CONFIG_BOARD_NBG6817)
        gpio_tlmm_config(pio, 0, GPIO_OUTPUT, GPIO_PULL_UP, DEFAULT_DRIVE_STRENGTH, GPIO_OE_ENABLE);
#else
        gpio_tlmm_config(pio, 0, GPIO_OUTPUT, GPIO_PULL_UP, DEFAULT_DRIVE_STRENGTH, GPIO_DISABLE);
#endif
    } else if (dir == ZGPIO_CONFIG_INPUT) {
        /* configure GPIO as input pin */
#if defined(CONFIG_BOARD_NBG6817)
        gpio_tlmm_config(pio, 0, GPIO_INPUT, GPIO_PULL_UP, DEFAULT_DRIVE_STRENGTH, GPIO_OE_DISABLE);
#else
        gpio_tlmm_config(pio, 0, GPIO_INPUT, GPIO_PULL_UP, DEFAULT_DRIVE_STRENGTH, GPIO_ENABLE);
#endif
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
    writel((level==ZGPIO_LEVEL_HIGH)?2:0, addr);
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
    *level = readl(addr)&1?ZGPIO_LEVEL_HIGH:ZGPIO_LEVEL_LOW;
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


