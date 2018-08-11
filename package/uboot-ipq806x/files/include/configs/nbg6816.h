
/* * Copyright (c) 2012 - 2014 The Linux Foundation. All rights reserved.* */

#ifndef _IPQCDP_H
#define _IPQCDP_H

/*
 * Disabled for actual chip.
 * #define CONFIG_RUMI
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
/*
 * Beat the system! tools/scripts/make-asm-offsets uses
 * the following hard-coded define for both u-boot's
 * ASM offsets and platform specific ASM offsets :(
 */
#include <generated/generic-asm-offsets.h>
#ifdef __ASM_OFFSETS_H__
#undef __ASM_OFFSETS_H__
#endif
#if !defined(DO_SOC_DEPS_ONLY)
#include <generated/asm-offsets.h>
#endif
#endif /* !DO_DEPS_ONLY */

#define CONFIG_BOARD_EARLY_INIT_F

#define CONFIG_SYS_NO_FLASH
#define CONFIG_IPQ806X_UART
#undef CONFIG_CMD_FLASH
#undef CONFIG_CMD_FPGA		        /* FPGA configuration support */
#undef CONFIG_CMD_IMI
#undef CONFIG_CMD_IMLS
#undef CONFIG_CMD_NFS		        /* NFS support */
#define CONFIG_CMD_NET		        /* network support */
#define CONFIG_CMD_DHCP
#undef CONFIG_SYS_MAX_FLASH_SECT
#define CONFIG_NR_DRAM_BANKS            1
#define CONFIG_SKIP_LOWLEVEL_INIT
#define CONFIG_CMD_PING
#define CONFIG_CMD_LOADB

#define CONFIG_BOARD_EARLY_INIT_F

/* Environment */
#define CONFIG_MSM_PCOMM
#define CONFIG_ARCH_CPU_INIT

#define CONFIG_ENV_SIZE                 (64 << 10) /* 64 KB */
#define CONFIG_SYS_MALLOC_LEN           (4 << 20)

/*-----------------------------------------------------------------------
 * Board Configuration
 */
#define CONFIG_BOARD_NBG6816            1
#define CONFIG_BOARD_NAME               "NBG6816"

#undef SENAO_FACTORY_BTN_GPIO_NO       53 //GPIO_WLAN_DISABLE_BTN
#undef SENAO_FACTORY_BTN_TRIGGER_LEVEL ZGPIO_LEVEL_LOW
#undef SENAO_FACTORY_IMG_FILE          "factoryNBG6816.bin"
#undef SENAO_FACTORY_IMG_SIZE_LIMIT    0x1300000 //19M


#define UPDATE_RAS_IMG_BTN_GPIO_NO      65 //GPIO_WPS_BTN
#define UPDATE_RAS_IMG_BTN_TRIGGER_LEVEL ZGPIO_LEVEL_LOW

#define FACTORY_RESET_BTN_GPIO_NO          54
#define FACTORY_RESET_BTN_TRIGGER_LEVEL    ZGPIO_LEVEL_LOW

#define NBG6816_SUPPORT_DISABLE_WAN_PORT 1
/*
 * Size of malloc() pool
 */

/*
 * select serial console configuration
 */
#define CONFIG_CONS_INDEX               1

/*
 * Enable crash dump support, this will dump the memory
 * regions via TFTP in case magic word found in memory
 */
#define CONFIG_IPQ_APPSBL_DLOAD

#define CONFIG_IPQ_ATAG_PART_LIST
#define IPQ_ROOT_FS_PART_NAME		"rootfs"

/* allow to overwrite serial and ethaddr */
#define CONFIG_ENV_OVERWRITE
#define CONFIG_BAUDRATE                 115200
#define CONFIG_SYS_BAUDRATE_TABLE       {4800, 9600, 19200, 38400, 57600,\
								115200}


#define CONFIG_SYS_PROMPT               CONFIG_BOARD_NAME "# " 
#define CONFIG_SYS_CBSIZE               (256 * 2) /* Console I/O Buffer Size */

#define CONFIG_SYS_INIT_SP_ADDR         CONFIG_SYS_SDRAM_BASE + GENERATED_IPQ_RESERVE_SIZE - GENERATED_GBL_DATA_SIZE
#define CONFIG_SYS_MAXARGS              16
#define CONFIG_SYS_PBSIZE               (CONFIG_SYS_CBSIZE + \
						sizeof(CONFIG_SYS_PROMPT) + 16)

#define CONFIG_SYS_SDRAM_BASE           0x40000000
#define CONFIG_SYS_TEXT_BASE            0x41200000
#define CONFIG_SYS_SDRAM_SIZE           0x10000000
#define CONFIG_MAX_RAM_BANK_SIZE        CONFIG_SYS_SDRAM_SIZE
#define CONFIG_SYS_LOAD_ADDR            (CONFIG_SYS_SDRAM_BASE + (64 << 20))

#define CONFIG_SERVERIP 192.168.1.99
#define CONFIG_IPADDR 192.168.1.1
#define CONFIG_ETHADDR 00:AA:BB:CC:DD:00

#ifndef __ASSEMBLY__
#include <compiler.h>
#ifndef __ZLOADER__
#include "../../board/qcom/ipq806x_cdp/ipq806x_cdp.h"
extern loff_t board_env_offset;
extern loff_t board_env_range;
extern uint32_t flash_index;
extern uint32_t flash_chip_select;
extern uint32_t flash_block_size;
extern board_ipq806x_params_t *gboard_param;
extern int rootfs_part_avail;

static uint32_t inline clk_is_dummy(void)
{
	return gboard_param->clk_dummy;
}
#endif

/*
 * XXX XXX Please do not instantiate this structure. XXX XXX
 * This is just a convenience to avoid
 *      - adding #defines for every new reservation
 *      - updating the multiple associated defines like smem base,
 *        kernel start etc...
 *      - re-calculation of the defines if the order changes or
 *        some reservations are deleted
 * For new reservations just adding a member to the structure should
 * suffice.
 * Ensure that the size of this structure matches with the definition
 * of the following IPQ806x compile time definitions
 *      PHYS_OFFSET     (linux-sources/arch/arm/mach-msm/Kconfig)
 *      zreladdr        (linux-sources/arch/arm/mach-msm/Makefile.boot)
 *      CONFIG_SYS_INIT_SP_ADDR defined above should point to the bottom.
 *      MSM_SHARED_RAM_PHYS (linux-sources/arch/arm/mach-msm/board-ipq806x.c)
 *
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
typedef struct {
	uint8_t	nss[16 * 1024 * 1024];
	uint8_t	smem[2 * 1024 * 1024];
	uint8_t	uboot[1 * 1024 * 1024];
	uint8_t	nsstcmdump[128 * 1024];
	uint8_t sbl3[384 * 1024];
	uint8_t plcfwdump[512*1024];
	uint8_t wlanfwdump[(1 * 1024 * 1024) - GENERATED_GBL_DATA_SIZE];
	uint8_t init_stack[GENERATED_GBL_DATA_SIZE];
} __attribute__ ((__packed__)) ipq_mem_reserve_t;

/* Convenience macros for the above convenience structure :-) */
#define IPQ_MEM_RESERVE_SIZE(x)		sizeof(((ipq_mem_reserve_t *)0)->x)
#define IPQ_MEM_RESERVE_BASE(x)		\
	(CONFIG_SYS_SDRAM_BASE + \
	 ((uint32_t)&(((ipq_mem_reserve_t *)0)->x)))
#endif

#define CONFIG_IPQ_SMEM_BASE		IPQ_MEM_RESERVE_BASE(smem)
#define IPQ_KERNEL_START_ADDR	\
	(CONFIG_SYS_SDRAM_BASE + GENERATED_IPQ_RESERVE_SIZE)

#define IPQ_DRAM_KERNEL_SIZE	\
	(CONFIG_SYS_SDRAM_SIZE - GENERATED_IPQ_RESERVE_SIZE)

#define IPQ_BOOT_PARAMS_ADDR		(IPQ_KERNEL_START_ADDR + 0x100)

#define IPQ_NSSTCM_DUMP_ADDR		(IPQ_MEM_RESERVE_BASE(nsstcmdump))

#define IPQ_TEMP_DUMP_ADDR		(IPQ_MEM_RESERVE_BASE(nsstcmdump))

#endif /* __ASSEMBLY__ */

#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_MEMTEST_START        CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END          CONFIG_SYS_MEMTEST_START + 0x100

#define CONFIG_CMDLINE_TAG	 1	/* enable passing of ATAGs */
#define CONFIG_SETUP_MEMORY_TAGS 1

#define CONFIG_CMD_IMI

#define CONFIG_CMD_SOURCE   1
#define CONFIG_INITRD_TAG   1

#define CONFIG_FIT
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_NULLDEV
#define CONFIG_CMD_XIMG

/*
 * SPI Flash Configs
 */

#define CONFIG_IPQ_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_SPANSION
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SYS_HZ                   1000

#define CONFIG_SF_DEFAULT_BUS 0
#define CONFIG_SF_DEFAULT_CS 0
#define CONFIG_SF_DEFAULT_MODE SPI_MODE_0
#define CONFIG_SF_DEFAULT_SPEED		(48 * 1000 * 1000)

/*
 * NAND Flash Configs
 */

#define CONFIG_IPQ_NAND
#define CONFIG_CMD_NAND
#define CONFIG_CMD_NAND_YAFFS
#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_NAND_SELF_INIT
#define CONFIG_SYS_NAND_ONFI_DETECTION

#define CONFIG_IPQ_MAX_SPI_DEVICE	1
#define CONFIG_IPQ_MAX_NAND_DEVICE	1

#define CONFIG_IPQ_NAND_NAND_INFO_IDX	0
#define CONFIG_IPQ_SPI_NAND_INFO_IDX	1

/*
 * Expose SPI driver as a pseudo NAND driver to make use
 * of U-Boot's MTD framework.
 */
#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
					 CONFIG_IPQ_MAX_SPI_DEVICE)

/*
 * U-Boot Env Configs
 */

#define CONFIG_ENV_IS_IN_NAND
#define CONFIG_CMD_SAVEENV
#define CONFIG_BOARD_LATE_INIT

#define CONFIG_OF_LIBFDT	1
#define CONFIG_OF_BOARD_SETUP	1

#if defined(CONFIG_ENV_IS_IN_NAND)

#define CONFIG_ENV_SPI_CS               flash_chip_select
#define CONFIG_ENV_SPI_MODE             SPI_MODE_0
#define CONFIG_ENV_OFFSET               board_env_offset
#define CONFIG_ENV_SECT_SIZE            flash_block_size
#define CONFIG_ENV_SPI_BUS              flash_index
#define CONFIG_ENV_RANGE		board_env_range

#else

#error "Unsupported env. type, should be NAND (even for SPI Flash)."

#endif

/* NSS firmware loaded using bootm */
#define CONFIG_IPQ_FIRMWARE
//#define CONFIG_BOOTCOMMAND  "bootipq"
#undef	CONFIG_BOOTARGS
/* CONFIG_ENV_VERSION
 *   v1.0: initial version
 *   v1.1: add environment variable 'env_readonly' to set partition 'env' as read-only
 *   v1.2: rename environment variable 'env_readonly' to 'readonly' for setting
 *         partition 'env' & 'RFData' as read-only
 *   v1.3: add environment variable 'zld_ver' to record zloader version and put it in
 *         kernel command line
 *   v1.4: set loader partition as ready-only mode, except in HTP mode.
 *         rename some environment variables for reduce code size
 *   v1.5: pass rootfstype=squashfs,jffs2 to kernel, let it can using SQUASHFS filesystem
 */
#define CONFIG_ENV_VERSION          "1.5"

//------------------------------------//
#define __gen_nand_cmd(cmd, offs, file, eraseCmd, writeCmd, eraseSize)	\
	#cmd "=tftp ${loadaddr} ${dir}" #file ";"						\
	#eraseCmd " " #offs " " #eraseSize ";"							\
	#writeCmd " ${fileaddr} " #offs " ${filesize}\0"

#define gen_nand_cmd(cmd, offs, file, partSize)			\
	__gen_nand_cmd(cmd, offs, file, nand erase, nand write, partSize)

#define __gen_cmd(cmd, offs, file, eraseCmd, writeCmd, eraseSize)	\
	#cmd "=tftpboot ${loadaddr} ${dir}" #file ";"						\
	#eraseCmd " " #offs " +" #eraseSize ";"							\
	#writeCmd " ${fileaddr} " #offs " ${filesize}\0"

#define gen_cmd(cmd, offs, file, partSize)							\
	__gen_cmd(cmd, offs, file, sf probe;sf erase, sf write, partSize)

#ifdef CONFIG_ZLOADER_SUPPORTED
#if 0
#define __gen_cmd(cmd, offs, file, eraseCmd, writeCmd, eraseSize)	\
	#cmd "=tftpboot ${loadaddr} ${dir}" #file ";"						\
	#eraseCmd " " #offs " " #eraseSize ";"							\
	#writeCmd " ${fileaddr} " #offs " ${filesize}\0"

#define gen_cmd(cmd, offs, file, partSize)							\
	__gen_cmd(cmd, offs, file, zflash erase, zflash write, partSize)
#endif
  #undef CONFIG_ZLD_IN_NAND
  #undef CONFIG_RAS_IN_NAND
  #undef CONFIG_ROMD_IN_NAND
  #undef CONFIG_ROMFILE_IN_NAND
  #define CONFIG_LZMA
  #define CONFIG_DISABLE_CONSOLE
  #define CONFIG_ZLOADER_FREE_RAM_BASE		IPQ_KERNEL_START_ADDR
#if 1
  #define CONFIG_ZLOADER_PART_SIZE		0x10000
  #define CONFIG_ZLOADER_PART_ADDR		0x1A4000//(CFG_LOADER_PART_ADDR +IPQ806X_SBL_LOADER_SIZE + NBG6816_U_BOOT_SIZE)  /* CFG_LOADER_PART_ADDR+U-BOOT(400KB)*/
#endif
  #define CONFIG_BOOT_ZLOADER_CMD		"sf probe&&sf read ${loadaddr} ${zld_paddr} ${zld_psize}&&bootm ${loadaddr}"
#endif

#define __gen_img_env_val(name, addr, size)	\
	#name "_paddr=" #addr "\0"			\
	#name "_psize=" #size "\0"

#define gen_img_env_val(name, addr, size)	\
	__gen_img_env_val(name, addr, size)

#ifdef CONFIG_ZLOADER_ROMD_SUPPORTED
  #define CONFIG_USING_ROMD_PARTITION 1
#endif
  #define IPQ806X_SBL_LOADER_ADDR     0x0
  #define IPQ806X_SBL_LOADER_SIZE     0x140000 //SBL1+MIBIB+SBL2+SBL3+DDRCONFIG+SSD+TZ+RPM = 0x140000
  #define NBG6816_U_BOOT_ADDR         0x140000
  #define NBG6816_U_BOOT_SIZE         0x64000
  #define NBG6816_U_BOOT_PLUS_ZLOADER_SIZE 0x80000
  #define NBG6816_ZLOADER_SIZE        0x1C000
  #define CFG_LOADER_PART_ADDR        IPQ806X_SBL_LOADER_ADDR //CONFIG_SYS_FLASH_BASE
  #define CFG_LOADER_PART_SIZE        0x1C0000//IPQ806X_SBL_LOADER_SIZE+NBG6816_U_BOOT_SIZE+NBG6816_ZLOADER_SIZE
  #define CFG_ENV_PART_ADDR           0x1c0000
  #define CFG_ENV_PART_SIZE           0x10000
  #define CFG_RFDATA_PART_ADDR        0x1d0000
  #define CFG_RFDATA_PART_SIZE        0x10000
  #define CFG_KERNEL_PART_ADDR        0x1e0000
  #define CFG_KERNEL_PART_SIZE        0x200000
  #define CFG_DUALFLAG_PART_ADDR      0x3E0000
  #define CFG_DUALFLAG_PART_SIZE      0x10000
  #define CFG_HEADER_PART_ADDR        0x3F0000
  #define CFG_HEADER_PART_SIZE        0x10000
  #define CFG_HEADER_IMG_SIZE         0x10000
  #define CFG_ROMD_PART_ADDR          0x400000
  #define CFG_ROMD_PART_SIZE          0x100000
  #define CFG_ROOTFSDATA_PART_ADDR    0x500000
  #define CFG_ROOTFSDATA_PART_SIZE    0x100000
  #define CFG_ROMDHDR_PART_SIZE       0x20
  #define CFG_ROOTFS_PART_ADDR        0x600000
  #define CFG_ROOTFS_PART_SIZE        0x1a00000
#ifndef CONFIG_USING_ROMD_PARTITION
  #error "Must be using ROMD partition for this configuration!"
#endif /* CONFIG_USING_ROMD_PARTITION */

  #define LOADER_IMG_ENV_VAL	gen_img_env_val(ldr, NBG6816_U_BOOT_ADDR, NBG6816_U_BOOT_PLUS_ZLOADER_SIZE)
  #define ENV_IMG_ENV_VAL	gen_img_env_val(env, CFG_ENV_PART_ADDR, CFG_ENV_PART_SIZE)
  #define RFDATA_IMG_ENV_VAL	gen_img_env_val(rfdat, CFG_RFDATA_PART_ADDR, CFG_RFDATA_PART_SIZE)
  #define RTFSDATA_IMG_ENV_VAL	gen_img_env_val(rfsdat, CFG_ROOTFSDATA_PART_ADDR, CFG_ROOTFSDATA_PART_SIZE)
  #define HEADER_IMG_ENV_VAL    gen_img_env_val(hdr, CFG_HEADER_PART_ADDR, CFG_HEADER_PART_SIZE)
  #define ROOTFS_IMG_ENV_VAL	gen_img_env_val(rfs, CFG_ROOTFS_PART_ADDR, CFG_ROOTFS_PART_SIZE)
  #define ROMD_IMG_ENV_VAL	gen_img_env_val(romd, CFG_ROMD_PART_ADDR, CFG_ROMD_PART_SIZE)
  #define HEADER1_IMG_ENV_VAL   gen_img_env_val(hdr1, CFG_HEADER1_PART_ADDR, CFG_HEADER1_PART_SIZE)
  #define ROOTFS1_IMG_ENV_VAL	gen_img_env_val(rfs1, CFG_ROOTFS1_PART_ADDR, CFG_ROOTFS1_PART_SIZE)
  #define BU1_IMG_ENV_VAL	gen_img_env_val(bu1, CFG_BU1_PART_ADDR, CFG_BU1_PART_SIZE)

  #define UPDATE_LOADER_CMD     gen_cmd(lu, ${ldr_paddr}, u-boot.mbn, ${ldr_psize})
  #define UPDATE_ROOTFS_CMD     gen_nand_cmd(lf, ${rfs_paddr}, ${img_prefix}rootfs.jffs2, ${rootfs_psize})
  #define KERNEL_IMG_ENV_VAL  gen_img_env_val(kernel, CFG_KERNEL_PART_ADDR, CFG_KERNEL_PART_SIZE)
  #define DUALFLAG_IMG_ENV_VAL  gen_img_env_val(dualflag, CFG_DUALFLAG_PART_ADDR, CFG_DUALFLAG_PART_SIZE)
  
  #define IMG_ENV_VAL           LOADER_IMG_ENV_VAL ENV_IMG_ENV_VAL RFDATA_IMG_ENV_VAL \
                                RTFSDATA_IMG_ENV_VAL ROMD_IMG_ENV_VAL HEADER_IMG_ENV_VAL \
				ROOTFS_IMG_ENV_VAL HEADER1_IMG_ENV_VAL KERNEL_IMG_ENV_VAL\
				ROOTFS1_IMG_ENV_VAL BU1_IMG_ENV_VAL DUALFLAG_IMG_ENV_VAL
//  #define MTDPARTS_IPQ_DEFAULT  "0x20000(SBL1)ro,0x20000(MIBIB)ro,0x20000(SBL2)ro,0x40000(SBL3)ro,0x10000(DDRCONFIG)ro,0x10000(SSD)ro,0x40000(TZ)ro,0x40000(RPM)ro,"
  #define MTDPARTS_IPQ_DEFAULT  "0x100000(SBL)ro,0x40000(RPM)ro,"
  #define MTDPARTS_DEFAULT      "mtdparts=m25p80:" MTDPARTS_IPQ_DEFAULT "${ldr_psize}(u-boot)${readonly},${env_psize}(env)${readonly},${rfdat_psize}(ART)${readonly},${kernel_psize}(HLOS),${dualflag_psize}(dualflag),${hdr_psize}(header),${romd_psize}(romd),${rfsdat_psize}(rootfs_data),${rfs_psize}(rootfs)"
//  #define ROOTFS_MTD_NO		"mtdblock17"
  #define UPGRADE_IMG_CMD	UPDATE_LOADER_CMD UPDATE_ROOTFS_CMD

  #define BOOT_FLASH_CMD        "boot_flash=run setmtdparts flashargs addtty addmtd;sf probe;sf read ${loadaddr} ${kernel_paddr} ${kernel_psize};bootm ${loadaddr}\0"
  #define BOOTARG_DEFAULT	"board=" CONFIG_BOARD_NAME " root=mtd:rootfs ${bootmode} ${zld_ver}"


/* ROOTFS_MTD_NO, MTDPARTS_DEFAULT, BOOT_FLASH_CMD, IMG_ENV_VAL, UPGRADE_IMG_CMD */
#define	CONFIG_EXTRA_ENV_SETTINGS					\
    "uboot_env_ver=" CONFIG_ENV_VERSION "\0" \
    "mtdids=nand1=m25p80\0" \
    "img_prefix=nbg6816-\0"	\
    "loadaddr=0x44000000\0" \
    "readonly=ro\0" \
    "setmtdparts=setenv mtdparts " MTDPARTS_DEFAULT "\0" \
    "flashargs=setenv bootargs " BOOTARG_DEFAULT "\0"  \
    "addtty=setenv bootargs ${bootargs} console=ttyHSL1,${baudrate}n8\0" \
    "addmtd=setenv bootargs ${bootargs} ${mtdparts}\0" \
    BOOT_FLASH_CMD \
    "bootcmd=run boot_flash\0" \
    IMG_ENV_VAL \
    UPGRADE_IMG_CMD \
    "countrycode=ff\0" \
    "serialnum=S100Z47000001\0" \
    "hostname=NBG6816\0"
//----------------------------------------------------//

#define CONFIG_CMD_ECHO
#define CONFIG_BOOTDELAY	3

#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_CMD_MTDPARTS

#define CONFIG_RBTREE		/* for ubi */
#define CONFIG_CMD_UBI

#define CONFIG_CMD_RUN
#define CONFIG_CMD_BOOTZ

#define CONFIG_IPQ_SNPS_GMAC

#define CONFIG_IPQ_SWITCH_ATHRS17

/* Add MBN header to U-Boot */
#define CONFIG_MBN_HEADER

#define CONFIG_SYS_RX_ETH_BUFFER	8

#ifdef CONFIG_IPQ_APPSBL_DLOAD
#define CONFIG_CMD_TFTPPUT
/* We will be uploading very big files */
#define CONFIG_NET_RETRY_COUNT 500
#endif
/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
 * Cache flush and invalidation based on L1 cache, so the cache line
 * size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE  64
//#define CONFIG_CMD_JFFS2
//#define CONFIG_CMD_JFFS2_ULOAD
//#define CONFIG_JFFS2_SUMMARY
/*#define CONFIG_SYS_DCACHE_OFF*/

#define CONFIG_IPQ_CACHE_ENABLE		1
#endif /* _IPQCDP_H */

