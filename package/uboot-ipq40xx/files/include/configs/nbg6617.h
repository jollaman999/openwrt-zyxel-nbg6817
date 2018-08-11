/*
 *
 * Copyright (c) 2015, The Linux Foundation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of The Linux Foundation nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef _IPQ40XX_CDP_H
#define _IPQ40XX_CDP_H

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

#define CONFIG_IPQ40XX
#define CONFIG_BOARD_EARLY_INIT_F
#define CONFIG_SYS_NO_FLASH
#define CONFIG_SYS_CACHELINE_SIZE	64
#define CONFIG_SKIP_LOWLEVEL_INIT
#define CONFIG_SYS_HZ			1000

#ifdef CONFIG_IPQ40XX_USB
#define CONFIG_USB_XHCI
#define CONFIG_CMD_USB
#define CONFIG_DOS_PARTITION
#define CONFIG_USB_STORAGE
#define CONFIG_SYS_USB_XHCI_MAX_ROOT_PORTS	2
#define CONFIG_USB_MAX_CONTROLLER_COUNT		2
#endif

#define CONFIG_QCOM_UART
#define CONFIG_CONS_INDEX		1
#define CONFIG_QCOM_BAM			1

#define CONFIG_ENV_OVERWRITE
#define CONFIG_BAUDRATE			115200
#define CONFIG_SYS_BAUDRATE_TABLE	{4800, 9600, 19200, 38400, 57600,\
								115200}
#define V_PROMPT			"(IPQ40xx) # "
#define CONFIG_SYS_PROMPT		V_PROMPT
#define CONFIG_SYS_CBSIZE		(256 * 2) /* Console I/O Buffer Size */
#define CONFIG_SYS_MAXARGS		16
#define CONFIG_SYS_PBSIZE		(CONFIG_SYS_CBSIZE + \
						sizeof(CONFIG_SYS_PROMPT) + 16)

#define CONFIG_SYS_SDRAM_BASE		0x80000000
#define CONFIG_SYS_TEXT_BASE		0x87300000
#define CONFIG_SYS_SDRAM_SIZE		0x10000000
#define CONFIG_SYS_INIT_SP_ADDR		(CONFIG_SYS_TEXT_BASE + 0x100000 - GENERATED_GBL_DATA_SIZE)
#define CONFIG_MAX_RAM_BANK_SIZE	CONFIG_SYS_SDRAM_SIZE
#define CONFIG_SYS_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (64 << 20))
#define CONFIG_DTB_LOAD_ADDR		(CONFIG_SYS_SDRAM_BASE + (96 << 20))
#define CONFIG_NR_DRAM_BANKS		1
#define CONFIG_OF_LIBFDT		1
#define CONFIG_OF_BOARD_SETUP		1

#ifdef CONFIG_IPQ40XX_I2C
#define CONFIG_CMD_I2C
#define CONFIG_SYS_I2C_SPEED	0
#endif

#ifdef CONFIG_IPQ40XX_PCI
#define CONFIG_PCI
#define CONFIG_CMD_PCI
#define CONFIG_PCI_SCAN_SHOW
#endif

#ifndef __ASSEMBLY__
#include <compiler.h>
#ifndef __ZLOADER__
extern loff_t board_env_offset;
extern loff_t board_env_range;
extern loff_t board_env_size;
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
 * of the following IPQ40xx compile time definitions
 *      PHYS_OFFSET     (linux-sources/arch/arm/mach-msm/Kconfig)
 *      zreladdr        (linux-sources/arch/arm/mach-msm/Makefile.boot)
 *      CONFIG_SYS_INIT_SP_ADDR defined above should point to the bottom.
 *      MSM_SHARED_RAM_PHYS (linux-sources/arch/arm/mach-msm/board-ipq40xx.c)
 *
 */
#if !defined(DO_DEPS_ONLY) || defined(DO_SOC_DEPS_ONLY)
typedef struct {
	uint8_t uboot[1024 * 1024 - GENERATED_GBL_DATA_SIZE];	/* ~1MB */
	uint8_t init_stack[GENERATED_GBL_DATA_SIZE];
	uint8_t sbl[1024 * 1024];				/* 1 MB */
	uint8_t cnss_debug[6 * 1024 * 1024];			/* 6 MB */
	uint8_t tz_apps[3 * 1024 * 1024];			/* 3 MB */
	uint8_t smem[512 * 1024];				/* 512 KB */
	uint8_t tz[1536 * 1024];				/* 1.5 MB */
} __attribute__ ((__packed__)) qca_mem_reserve_t;

#define QCA_MEM_RESERVE_SIZE(x)		sizeof(((qca_mem_reserve_t *)0)->x)
#define QCA_MEM_RESERVE_BASE(x)		\
	(CONFIG_SYS_TEXT_BASE + \
	 ((uint32_t)&(((qca_mem_reserve_t *)0)->x)))
#endif

#define CONFIG_QCA_SMEM_BASE		0x87e00000
#define QCA_KERNEL_START_ADDR	\
	(CONFIG_SYS_SDRAM_BASE + GENERATED_QCA_RESERVE_SIZE)

#define QCA_DRAM_KERNEL_SIZE	\
	(CONFIG_SYS_SDRAM_SIZE - GENERATED_QCA_RESERVE_SIZE)

#define QCA_BOOT_PARAMS_ADDR	(QCA_KERNEL_START_ADDR + 0x100)
#endif

#define IPQ_ROOT_FS_PART_NAME		"rootfs"

/* Environment */
#define CONFIG_IPQ40XX_ENV
#define CONFIG_ARCH_CPU_INIT
#define CONFIG_ENV_IS_IN_NAND
#define CONFIG_CMD_SAVEENV
#define CONFIG_BOARD_LATE_INIT
#define CONFIG_ENV_OFFSET		board_env_offset
#define CONFIG_ENV_SIZE_MAX		(256 << 10) /* 256 KB */
#define CONFIG_ENV_RANGE		board_env_size
#define CONFIG_ENV_SIZE			board_env_range
#define CONFIG_SYS_MALLOC_LEN		(CONFIG_ENV_SIZE_MAX + (256 << 10))

#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_MEMTEST_START	CONFIG_SYS_SDRAM_BASE + 0x1300000
#define CONFIG_SYS_MEMTEST_END		CONFIG_SYS_MEMTEST_START + 0x100
#define CONFIG_CMD_SOURCE		1
#define CONFIG_INITRD_TAG		1
#define CONFIG_FIT
#define CONFIG_SYS_HUSH_PARSER
#define CONFIG_SYS_NULLDEV
#define CONFIG_CMD_XIMG
#define CONFIG_CMD_NET

/* L1 cache line size is 64 bytes, L2 cache line size is 128 bytes
 * Cache flush and invalidation based on L1 cache, so the cache line
 * size is configured to 64 */
#define CONFIG_SYS_CACHELINE_SIZE	64

/* CMDS */
#define	CONFIG_CMD_RUN

/*
 * NAND Flash Configs
 */

/* CONFIG_QPIC_NAND: QPIC NAND in BAM mode
 * CONFIG_IPQ_NAND: QPIC NAND in FIFO/block mode.
 * BAM is enabled by default.
 */
#define CONFIG_QPIC_NAND
#define CONFIG_CMD_NAND
#define CONFIG_CMD_NAND_YAFFS
#define CONFIG_CMD_MEMORY
#define CONFIG_SYS_NAND_SELF_INIT
#define CONFIG_SYS_NAND_ONFI_DETECTION

/*
 * Expose SPI driver as a pseudo NAND driver to make use
 * of U-Boot's MTD framework.
 */
#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
					CONFIG_IPQ_MAX_SPI_DEVICE)

#define CONFIG_IPQ_MAX_SPI_DEVICE	2
#define CONFIG_IPQ_MAX_NAND_DEVICE	1

#define CONFIG_IPQ_NAND_NAND_INFO_IDX	0
#define CONFIG_QPIC_NAND_NAND_INFO_IDX	0
#define CONFIG_IPQ_SPI_NAND_INFO_IDX	1
#define CONFIG_IPQ_SPI_NOR_INFO_IDX	2

#define CONFIG_FDT_FIXUP_PARTITIONS

/*
 * SPI Flash Configs
 */

#define CONFIG_QCA_SPI
#define CONFIG_SPI_FLASH
#define CONFIG_CMD_SF
#define CONFIG_SPI_FLASH_STMICRO
#define CONFIG_SPI_FLASH_WINBOND
#define CONFIG_SPI_FLASH_MACRONIX
#define CONFIG_SPI_FLASH_GIGA
#define CONFIG_SPI_NOR_GENERIC
#define CONFIG_IPQ40XX_SPI

#define CONFIG_SF_DEFAULT_BUS 0
#define CONFIG_SF_DEFAULT_CS 0
#define CONFIG_SF_SPI_NAND_CS 1
#define CONFIG_SF_DEFAULT_MODE SPI_MODE_0
#define CONFIG_IPQ40XX_XIP	1

#define CONFIG_QUP_SPI_USE_DMA 1

#define CONFIG_SPI_NAND_GIGA 1
#define CONFIG_SPI_NAND_ATO
#define CONFIG_SPI_NAND_MACRONIX
#define CONFIG_SPI_NAND_WINBOND

#define CONFIG_SF_DEFAULT_SPEED         (48 * 1000 * 1000)

/*
 * ESS Configs
 */
#define CONFIG_CMD_PING
#define CONFIG_CMD_DHCP
#define CONFIG_IPQ40XX_ESS	1
#define CONFIG_IPQ40XX_EDMA	1
#define CONFIG_NET_RETRY_COUNT		5
#define CONFIG_SYS_RX_ETH_BUFFER	16
#define CONFIG_IPQ40XX_MDIO	1
#define CONFIG_QCA8075_PHY	1
#define CONFIG_QCA8033_PHY	1
#define CONFIG_MII
#define CONFIG_CMD_MII
#define CONFIG_IPADDR	192.168.1.11
#define CONFIG_IPQ_NO_MACS	2
/*
 * CRASH DUMP ENABLE
 */

#define CONFIG_QCA_APPSBL_DLOAD	1

#ifdef CONFIG_QCA_APPSBL_DLOAD
#define CONFIG_CMD_TFTPPUT
/* We will be uploading very big files */
#undef CONFIG_NET_RETRY_COUNT
#define CONFIG_NET_RETRY_COUNT 500
#endif
#define CONFIG_CMD_ECHO

/*
 * Expose SPI driver as a pseudo NAND driver to make use
 * of U-Boot's MTD framework.
 */
#define CONFIG_SYS_MAX_NAND_DEVICE	(CONFIG_IPQ_MAX_NAND_DEVICE + \
					 CONFIG_IPQ_MAX_SPI_DEVICE)

#undef CONFIG_QCA_MMC

#ifdef CONFIG_QCA_MMC
#define CONFIG_CMD_MMC
#define CONFIG_MMC
#define CONFIG_EFI_PARTITION
#define CONFIG_GENERIC_MMC
#define CONFIG_ENV_IS_IN_MMC
#define CONFIG_SYS_MMC_ENV_DEV  0
#endif


#define CONFIG_MTD_DEVICE
#define CONFIG_MTD_PARTITIONS
#define CONFIG_CMD_MTDPARTS

#define CONFIG_RBTREE		/* for ubi */
#define CONFIG_CMD_UBI
#define CONFIG_BOOTCOMMAND	"bootipq"
#define CONFIG_BOOTDELAY	3
#define CONFIG_IPQ_FDT_HIGH	0x87000000


/*-----------------------------------------------------------------------
 * Board Configuration
 */
#define CONFIG_BOARD_NBG6617            1
#define CONFIG_BOARD_NAME               "NBG6617"

//#undef SENAO_FACTORY_BTN_GPIO_NO       2 //GPIO_WLAN_DISABLE_BTN
//#undef SENAO_FACTORY_BTN_TRIGGER_LEVEL ZGPIO_LEVEL_LOW
//#undef SENAO_FACTORY_IMG_FILE          "factoryNBG6617.bin"
//#undef SENAO_FACTORY_IMG_SIZE_LIMIT    0x1300000 //19M


#define UPDATE_RAS_IMG_BTN_GPIO_NO      63 //GPIO_WPS_BTN
#define UPDATE_RAS_IMG_BTN_TRIGGER_LEVEL ZGPIO_LEVEL_LOW

#define FACTORY_RESET_BTN_GPIO_NO          4
#define FACTORY_RESET_BTN_TRIGGER_LEVEL    ZGPIO_LEVEL_LOW

#define NBG6617_SUPPORT_DISABLE_WAN_PORT 1

#ifdef CONFIG_SYS_PROMPT
#undef CONFIG_SYS_PROMPT
#endif
#define CONFIG_SYS_PROMPT               CONFIG_BOARD_NAME "# "

#define CONFIG_SERVERIP                 192.168.1.99
#ifdef CONFIG_IPADDR
#undef CONFIG_IPADDR
#endif
#define CONFIG_IPADDR                   192.168.1.1
//#define CONFIG_ETHADDR                  00:AA:BB:CC:DD:00

//#ifdef CONFIG_BOOTCOMMAND
//#undef CONFIG_BOOTCOMMAND
//#endif

//#ifdef CONFIG_QCA_MMC
//#undef CONFIG_QCA_MMC
//#endif

//#ifdef CONFIG_CMD_UBI
//#undef CONFIG_CMD_UBI
//#endif

#define CONFIG_CMD_LOADB

#define CONFIG_SUPPORT_DISABLE_WAN_PORT

#define CONFIG_ENV_VERSION          "1.5"

#define __gen_img_env_val(name, addr, size)	\
	#name "_paddr=" #addr "\0"			\
	#name "_psize=" #size "\0"

#define gen_img_env_val(name, addr, size)	\
	__gen_img_env_val(name, addr, size)

#define __gen_flash_erase_cmd(cmd, offs, eraseSize) \
	#cmd "=sf probe; sf erase " #offs " +" #eraseSize "\0"							\

#define gen_flash_erase_cmd(cmd, offs, eraseSize)	\
	__gen_flash_erase_cmd(cmd, offs, eraseSize)

#ifdef CONFIG_ZLOADER_SUPPORTED
  #undef CONFIG_ZLD_IN_NAND
  #undef CONFIG_RAS_IN_NAND
  #undef CONFIG_ROMD_IN_NAND
  #undef CONFIG_ROMFILE_IN_NAND
  #define CONFIG_LZMA
  #define CONFIG_DISABLE_CONSOLE
  #define CONFIG_ZLOADER_FREE_RAM_BASE          QCA_KERNEL_START_ADDR
#if 1
  #define CONFIG_ZLOADER_PART_SIZE              0x10000
  #define CONFIG_ZLOADER_PART_ADDR              0x144000//(CFG_LOADER_PART_ADDR(0x0) +IPQ40XX_SBL_LOADER_SIZE + NBG6617_U_BOOT_SIZE 0x64000)
#endif
  #define CONFIG_BOOT_ZLOADER_CMD               "sf probe&&sf read ${loadaddr} ${zld_paddr} ${zld_psize}&&bootm ${loadaddr}"
#ifdef CONFIG_ZLOADER_ROMD_SUPPORTED
  #define CONFIG_USING_ROMD_PARTITION 1
#endif

#endif

#define IPQ40XX_SBL_LOADER_ADDR     0x0
#define IPQ40XX_SBL_LOADER_SIZE     0xE0000 //SBL1+MIBIB+QSEE+CDT+DDRPARAMS

#define U_BOOT_ADDR                 0xE0000
#define U_BOOT_SIZE                 0x64000
#define U_BOOT_PLUS_ZLOADER_SIZE    0x80000
#define ZLOADER_SIZE                0x1C000
#if defined(U_BOOT_ADDR) && defined(U_BOOT_PLUS_ZLOADER_SIZE)
  #define LOADER_IMG_ENV_VAL	gen_img_env_val(ldr, U_BOOT_ADDR, U_BOOT_PLUS_ZLOADER_SIZE)
  //#define UPDATE_LOADER_CMD     gen_cmd(lu, ${ldr_paddr}, u-boot.mbn, ${ldr_psize})
#else
  #error "Must define U_BOOT_ADDR and U_BOOT_PLUS_ZLOADER_SIZE!"
#endif

#define CFG_LOADER_PART_ADDR        IPQ40XX_SBL_LOADER_ADDR //CONFIG_SYS_FLASH_BASE
#define CFG_LOADER_PART_SIZE        (IPQ40XX_SBL_LOADER_SIZE + U_BOOT_SIZE + ZLOADER_SIZE) // 0x160000

#define CFG_ENV_PART_ADDR           0x160000
#define CFG_ENV_PART_SIZE           0x10000
#if defined(CFG_ENV_PART_ADDR) && defined(CFG_ENV_PART_SIZE)
  #define ENV_IMG_ENV_VAL	gen_img_env_val(env, CFG_ENV_PART_ADDR, CFG_ENV_PART_SIZE)
  #define ERASE_ENV_CMD         gen_flash_erase_cmd(eenv, ${env_paddr}, ${env_psize})
#else
  #error "Must define CFG_ENV_PART_ADDR and CFG_ENV_PART_SIZE!"
#endif

#define CFG_RFDATA_PART_ADDR        0x170000
#define CFG_RFDATA_PART_SIZE        0x10000
#if defined(CFG_RFDATA_PART_ADDR) && defined(CFG_RFDATA_PART_SIZE)
  #define RFDATA_IMG_ENV_VAL	gen_img_env_val(rfdat, CFG_RFDATA_PART_ADDR, CFG_RFDATA_PART_SIZE)
  #define ERASE_RFDATA_CMD      gen_flash_erase_cmd(eerfdat, ${rfdat_paddr}, ${rfdat_psize})
#endif

#define CFG_KERNEL_PART_ADDR        0x180000
#define CFG_KERNEL_PART_SIZE        0x400000
#if defined(CFG_KERNEL_PART_ADDR) && defined(CFG_KERNEL_PART_SIZE)
  #define KERNEL_IMG_ENV_VAL  gen_img_env_val(kernel, CFG_KERNEL_PART_ADDR, CFG_KERNEL_PART_SIZE)
#endif

#define CFG_DUALFLAG_PART_ADDR      0x580000
#define CFG_DUALFLAG_PART_SIZE      0x10000
#if defined(CFG_DUALFLAG_PART_ADDR) && defined(CFG_DUALFLAG_PART_SIZE)
  #define DUALFLAG_IMG_ENV_VAL  gen_img_env_val(dualflag, CFG_DUALFLAG_PART_ADDR, CFG_DUALFLAG_PART_SIZE)
  #define ERASE_DUALFLAG_CMD    gen_flash_erase_cmd(eedualflag, ${dualflag_paddr}, ${dualflag_psize})
  #undef CFG_ZYXEL_DUALFLAG
#endif

#define CFG_HEADER_PART_ADDR        0x590000
#define CFG_HEADER_PART_SIZE        0x10000
#define CFG_HEADER_IMG_SIZE         0x10000 // byte-size
#if defined(CFG_HEADER_PART_ADDR) && defined(CFG_HEADER_PART_SIZE)
  #define HEADER_IMG_ENV_VAL    gen_img_env_val(hdr, CFG_HEADER_PART_ADDR, CFG_HEADER_PART_SIZE)
  #define HEADER_IMG_ENV_VAL   gen_img_env_val(hdr, CFG_HEADER_PART_ADDR, CFG_HEADER_PART_SIZE)
#endif

#define CFG_ROMD_PART_ADDR          0x5A0000
#define CFG_ROMD_PART_SIZE          0x100000
#define CFG_ROMDHDR_PART_SIZE       0x20
#if defined(CFG_ROMD_PART_ADDR) && defined(CFG_ROMD_PART_SIZE)
  #define ROMD_IMG_ENV_VAL	gen_img_env_val(romd, CFG_ROMD_PART_ADDR, CFG_ROMD_PART_SIZE)
#endif

#define CFG_ROOTFSDATA_PART_ADDR    0x6A0000
#define CFG_ROOTFSDATA_PART_SIZE    0x100000
#if defined(CFG_ROOTFSDATA_PART_ADDR) && defined(CFG_ROOTFSDATA_PART_SIZE)
  #define RTFSDATA_IMG_ENV_VAL	gen_img_env_val(rfsdat, CFG_ROOTFSDATA_PART_ADDR, CFG_ROOTFSDATA_PART_SIZE)
#endif

#define CFG_ROOTFS_PART_ADDR        0x7A0000
#define CFG_ROOTFS_PART_SIZE        0x1860000
#if defined(CFG_ROOTFS_PART_ADDR) && defined(CFG_ROOTFS_PART_SIZE)
  #define ROOTFS_IMG_ENV_VAL	gen_img_env_val(rfs, CFG_ROOTFS_PART_ADDR, CFG_ROOTFS_PART_SIZE)
#endif

#define IMG_ENV_VAL           LOADER_IMG_ENV_VAL ENV_IMG_ENV_VAL RFDATA_IMG_ENV_VAL DUALFLAG_IMG_ENV_VAL \
                                RTFSDATA_IMG_ENV_VAL ROMD_IMG_ENV_VAL \
				HEADER_IMG_ENV_VAL KERNEL_IMG_ENV_VAL ROOTFS_IMG_ENV_VAL

#define MTDPARTS_IPQ_DEFAULT  "0x60000@0x60000(0:QSEE)ro,"
#define MTDPARTS_DEFAULT      "mtdparts=spi0.0:" MTDPARTS_IPQ_DEFAULT "${ldr_psize}@${ldr_paddr}(u-boot)${readonly},${env_psize}(env)${readonly},${rfdat_psize}(0:ART)${readonly},${kernel_psize}(HLOS),${dualflag_psize}(dualflag),${hdr_psize}(header),${romd_psize}(romd),${rfsdat_psize}(rootfs_data),${rfs_psize}(rootfs)"

#define UPGRADE_IMG_CMD	\
                        ERASE_ENV_CMD ERASE_RFDATA_CMD ERASE_DUALFLAG_CMD

#define BOOT_FLASH_CMD        "boot_flash=run setmtdparts flashargs addmtd;sf probe;sf read ${loadaddr} ${kernel_paddr} ${kernel_psize};bootm ${loadaddr}\0"
#define BOOTARG_DEFAULT	"board=" CONFIG_BOARD_NAME " root=mtd:rootfs ${bootmode} ${zld_ver}"



/* ROOTFS_MTD_NO, MTDPARTS_DEFAULT, BOOT_FLASH_CMD, IMG_ENV_VAL, UPGRADE_IMG_CMD */
#define	CONFIG_EXTRA_ENV_SETTINGS					\
    "uboot_env_ver=" CONFIG_ENV_VERSION "\0" \
    "mtdids=nand2=spi0.0\0" \
    "fdt_high=0x87000000\0" \
    "img_prefix=nbg6617-\0"	\
    "loadaddr=0x84000000\0" \
    "bootmode=HTP=1\0" \
    "setmtdparts=setenv mtdparts " MTDPARTS_DEFAULT "\0" \
    "flashargs=setenv bootargs " BOOTARG_DEFAULT "\0"  \
    "addmtd=setenv bootargs ${bootargs} ${mtdparts}\0" \
    BOOT_FLASH_CMD \
    "bootcmd=run boot_flash\0" \
    IMG_ENV_VAL \
    UPGRADE_IMG_CMD \
    "countrycode=ff\0" \
    "serialnum=S100Z47000001\0" \
    "hostname=NBG6617\0"
//----------------------------------------------------//
#endif /* _IPQCDP_H */
