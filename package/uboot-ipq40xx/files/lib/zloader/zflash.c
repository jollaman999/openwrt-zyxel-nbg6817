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
 * Program: flash driver for zloader
 *  Author: Chang-Hsing Lee.(changhsing.lee@zyxel.com.tw), 2012/6/19
 *****************************************************************************/
#include <common.h>
#include <exports.h>

#if defined(CONFIG_SPI_FLASH)
#include <spi.h>
#include <spi_flash.h>
static struct spi_flash *flash=NULL;
#elif !defined(CONFIG_SYS_NO_FLASH)
#include <flash.h>
#define NOR_FLASH_DEVICE_INDEX      0
extern flash_info_t  flash_info[]; /* info for FLASH chips */
#endif

#ifdef CONFIG_CMD_NAND
#include <nand.h>
#define NAND_FLASH_DEVICE_INDEX      0
int znand_init(void)
{
    /* TODO */
    return 0;
}

int znand_read(unsigned long offs, unsigned long len, char *buf)
{
    return nand_read_skip_bad(&nand_info[NAND_FLASH_DEVICE_INDEX], offs, &len, (u_char *)buf);
}

int znand_oob_read(unsigned long offs, char *oobbuf)
{
    int i;
    struct mtd_oob_ops ops;
    loff_t addr = (loff_t) offs;

    if (oobbuf==NULL) {
        return 0;
    }

    memset(&ops, 0, sizeof(ops));
    ops.datbuf = NULL;
    ops.oobbuf = (uint8_t *)oobbuf;
    ops.len = 0;
    ops.ooblen = nand_info[NAND_FLASH_DEVICE_INDEX].oobsize;
    ops.mode = MTD_OOB_RAW;
    if (nand_info[NAND_FLASH_DEVICE_INDEX].read_oob(&nand_info[NAND_FLASH_DEVICE_INDEX], addr, &ops) < 0)
        return -1;
    if (ops.ooblen != ops.oobretlen)
        return -2;
    return 0;
}

int znand_write(unsigned long offs, unsigned long boundary, unsigned long len, char *buf)
{
    return nand_write_skip_bad(&nand_info[NAND_FLASH_DEVICE_INDEX], offs, &len, (u_char *)buf, 0);
}

int znand_erase(unsigned long offs, unsigned long boundary, unsigned long len)
{
    nand_erase_options_t opts;
    opts.offset = offs;
    opts.length = len;
    opts.quiet = 0;
    opts.jffs2 = 0;
    opts.scrub = 0;

    return nand_erase_opts(&nand_info[NAND_FLASH_DEVICE_INDEX], &opts);
}

unsigned long znand_block_size(void)
{
    return nand_info[NAND_FLASH_DEVICE_INDEX].erasesize;
}

unsigned long znand_page_size(void)
{
    return nand_info[NAND_FLASH_DEVICE_INDEX].writesize;
}

unsigned long znand_oob_size(void)
{
    return nand_info[NAND_FLASH_DEVICE_INDEX].oobsize;
}

#else
int znand_init(void)
{
    return -1;
}
int znand_read(unsigned long offs, unsigned long len, char *buf)
{
    return -1;
}
int znand_write(unsigned long offs, unsigned long len, char *buf)
{
    return -1;
}
int znand_erase(unsigned long offs, unsigned long len)
{
    return -1;
}
unsigned long znand_block_size(void)
{
    return 0;
}
unsigned long znand_page_size(void)
{
    return 0;
}
unsigned long znand_oob_size(void)
{
    return 0;
}
#endif /* ifdef CONFIG_CMD_NAND */

int zflash_init(void)
{
#if defined(CONFIG_SPI_FLASH)
    /* have SPI NOR flash */
    if (flash==NULL) {
        DECLARE_GLOBAL_DATA_PTR;
        gd->flags |= GD_FLG_DISABLE_CONSOLE; /* disable console */
        flash = spi_flash_probe(CONFIG_SF_DEFAULT_BUS, CONFIG_SF_DEFAULT_CS,
                CONFIG_SF_DEFAULT_SPEED, CONFIG_SF_DEFAULT_MODE);
        gd->flags &= (~GD_FLG_DISABLE_CONSOLE); /* enable console */
        if ( flash == NULL ) {
            printf("!!! not found SPI flash !!!\n");
            return -1;
        }
    }
#elif !defined(CONFIG_SYS_NO_FLASH)
    /* have parallel NOR flash */
    /* TODO */
#else
    #error "Unknown type of NOR flash!"
#endif
    return 0;
}

int zflash_read(unsigned long offs, unsigned long len, char *buf)
{
    DECLARE_GLOBAL_DATA_PTR __maybe_unused;
    if ( buf == NULL ) {
        return -1;
    }
#if defined(CONFIG_SPI_FLASH)
    if (flash==NULL) {
        return -2;
    }
    return flash->read(flash, offs, len, buf);
#elif !defined(CONFIG_SYS_NO_FLASH) /* parallel NOR flash */
    if ( offs<CONFIG_SYS_FLASH_BASE || offs+len>(CONFIG_SYS_FLASH_BASE+gd->ram_size) ) {
        return -3;
    }
    memcpy(buf, (void *)offs, len);
    flush_cache((unsigned long)buf, len);
#endif
    return 0;
}

int zflash_write(unsigned long offs, unsigned long len, char *buf)
{
    if ( buf == NULL ) {
        return -1;
    }
#if defined(CONFIG_SPI_FLASH)
    if (flash==NULL) {
        return -2;
    }
    return flash->write(flash, offs, len, buf);
#elif !defined(CONFIG_SYS_NO_FLASH)
    extern int flash_write (char *src, ulong addr, ulong cnt);
    return flash_write (buf, offs, len);
#endif
    return 0;
}

int zflash_erase(unsigned long offs, unsigned long len)
{
#if defined(CONFIG_SPI_FLASH) /* serial NOR flash */
    if (flash==NULL) {
        return -2;
    }
    return flash->erase(flash, offs, len);
#elif !defined(CONFIG_SYS_NO_FLASH) /* parallel NOR flash */
    extern int flash_sect_erase (ulong addr_first, ulong addr_last);
    return flash_sect_erase(offs, offs+len-1);
#endif
    return 0;
}

unsigned long zflash_block_size(unsigned long blkNo)
{
    unsigned long size = 0;
#if defined(CONFIG_SPI_FLASH) /* serial NOR flash */
    if ( flash != NULL ) {
        size = flash->sector_size;
    }
#elif !defined(CONFIG_SYS_NO_FLASH) /* parallel NOR flash */
    if ( blkNo<flash_info[NOR_FLASH_DEVICE_INDEX].sector_count ) {
        size = flash_sector_size(&flash_info[NOR_FLASH_DEVICE_INDEX], blkNo);
    }
#endif
    return size;
}

#ifdef CONFIG_ZFLASH_CMD
#include <command.h>
enum {
    ATCMD_FLASH_TYPE_NOR=0,
    ATCMD_FLASH_TYPE_NAND,
    ATCMD_FLASH_MAX_TYPE
};
static unsigned int zflash_cmd_type=0; // 0-NOR flash, 1-NAND flash
static int do_zflash_cmd(cmd_tbl_t *cmdtp, int flag, int argc, char *argv[])
{
	if ( argc < 3 ) {
		goto zflash_cmd_failed;
	}

    if (argc>=3 && !strncmp(argv[1], "switch", 7)) {
        unsigned int type;
        if ((type=simple_strtoul(argv[2], NULL, 16)>= ATCMD_FLASH_MAX_TYPE)) {
            zflash_cmd_type = 0;
        } else {
            zflash_cmd_type = type;
        }
        printf("%s flash commands activated\n", zflash_cmd_type?"NAND":"NOR");
	} else if (argc>=5 && !strncmp(argv[1], "read", 5)) {
		unsigned long addr, offs, len;
		addr = simple_strtoul(argv[2], NULL, 16);
		offs = simple_strtoul(argv[3], NULL, 16);
		len = simple_strtoul(argv[4], NULL, 16);
		if ( zflash_cmd_type==ATCMD_FLASH_TYPE_NAND?znand_read(offs, len, (char *)addr):zflash_read(offs, len, (char *)addr) ) return -1;
	} else if (argc>=4 && !strncmp(argv[1], "erase", 6)) {
		unsigned int o, l;
		o = simple_strtoul(argv[2], NULL, 16);
		l = simple_strtoul(argv[3], NULL, 16);
		if ( zflash_cmd_type==ATCMD_FLASH_TYPE_NAND?znand_erase(o, 0, l):zflash_erase(o, l) ) return -1;
	} else if (argc>=5 && !strncmp(argv[1], "write", 6)) {
		unsigned long addr, offs, len;
		addr = simple_strtoul(argv[2], NULL, 16);
		offs = simple_strtoul(argv[3], NULL, 16);
		len = simple_strtoul(argv[4], NULL, 16);
		if ( zflash_cmd_type==ATCMD_FLASH_TYPE_NAND?znand_write(offs, 0, len, (char *)addr):zflash_write(offs, len, (char *)addr) ) return -1;
	} else {
zflash_cmd_failed:
	#ifdef	CONFIG_SYS_LONGHELP
		printf("\nUsage:\n%s\n", cmdtp->help);
	#else
		printf("wrong syntax\n");
	#endif
			return -1;
	}
	return 0;
}

U_BOOT_CMD (
	zflash,	5,	0, 	do_zflash_cmd,
	"Flash access commands, length must be align to block/page size",
    "switch <0-NOR|1-NAND>                   - switch flash type for commands"
	"zflash erase <offs> <len>        - erase flash\n"
	"zflash read <addr> <offs> <len>  - read data from flash to memory\n"
	"zflash write <addr> <offs> <len> - write data from memory to flash\n"
    "  <addr>: memory address\n"
    "  <offs>: flash offset/address\n"
);
#endif

