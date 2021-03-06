#ifndef __COMCERTO_1XX_H__
#define __COMCERTO_1XX_H__

/* to be moved somewhere else */
#ifndef __ASSEMBLY__
#include <asm/byteorder.h>
#endif

#define FAILURE           0
#define SUCCESS           1
#define UNSET             0 	// pay attention that it is out of the LOW..HIGH values, so it will not be a possible value

#define BYTE_SZ		8
#define HALF_WORD	16
#define WORD		32
#define DOUBLE_WORD	64

#define BOARD_CFG_1	1	/* ASIC board 256MB Micron */
#define BOARD_CFG_2	2	/* ASIC board 1GB Micron */
#define BOARD_CFG_3	3	/* ASIC board 1GB Samsum */
#define BOARD_CFG_4	4	/* Packet IAD 128MB */
#define BOARD_CFG_5	5	/* Router Board 64MB */
#define BOARD_CFG_6	6	/* ASIC board 256MB Micron */
#define BOARD_CFG_7	7	/* FE Router Board 64MB */
#define BOARD_CFG_MOCA  8       /* MoCA EVM 128MB */
#define BOARD_CFG_8     8       /* MoCA EVM 128MB */
#define BOARD_CFG_9     9       /* Packet IAD C50 64MB */
#define BOARD_CFG_10   10       /* Router C50 */

/* memcore */
/* device memory base addresses */
// device memory sizes
#define ARAM_SIZE		0x00010000 /* 64K */
#define ARAM_BASEADDR		0x0A000000

/* Hardware Interface Units */
#define APB_BASEADDR		0x10000000
#define APB_SIZE		0x01000000 /* 16M address range */

#define EXP_CS0_BASEADDR	0x20000000
#define EXP_CS1_BASEADDR	0x24000000
#define EXP_CS2_BASEADDR	0x28000000
#define EXP_CS3_BASEADDR	0x2C000000
#define EXP_CS4_BASEADDR	0x30000000

#define DDR_BASEADDR		0x80000000

#define TDM_BASEADDR		(APB_BASEADDR + 0x000000)
#define PHI_BASEADDR		(APB_BASEADDR + 0x010000)
#define TDMA_BASEADDR		(APB_BASEADDR + 0x020000)
#define ASA_DDR_BASEADDR	(APB_BASEADDR + 0x040000)
#define ASA_ARAM_BASEADDR	(APB_BASEADDR + 0x048000)
#define TIMER_BASEADDR		(APB_BASEADDR + 0x050000)
#define ASD_BASEADDR		(APB_BASEADDR + 0x060000)
#define GPIO_BASEADDR		(APB_BASEADDR + 0x070000)
#define UART0_BASEADDR		(APB_BASEADDR + 0x090000)
#define UART1_BASEADDR		(APB_BASEADDR + 0x094000)
#define SPI_BASEADDR		(APB_BASEADDR + 0x098000)
#define I2C_BASEADDR		(APB_BASEADDR + 0x09C000)
#define INTC_BASEADDR		(APB_BASEADDR + 0x0A0000)
#define CLKCORE_BASEADDR	(APB_BASEADDR + 0x0B0000)
#define PUI_BASEADDR		(APB_BASEADDR + 0x0B0000)
#define GEMAC_BASEADDR		(APB_BASEADDR + 0x0D0000)
#define IDMA_BASEADDR		(APB_BASEADDR + 0x0E0000)
#define MEMCORE_BASEADDR	(APB_BASEADDR + 0x0F0000)
#define ASA_EBUS_BASEADDR	(APB_BASEADDR + 0x100000)
#define ASA_AAB_BASEADDR	(APB_BASEADDR + 0x108000)
#define GEMAC1_BASEADDR		(APB_BASEADDR + 0x190000)
#define EBUS_BASEADDR		(APB_BASEADDR + 0x1A0000)
#define MDMA_BASEADDR		(APB_BASEADDR + 0x1E0000)


////////////////////////////////////////////////////////////
//	IDMA block											    //
////////////////////////////////////////////////////////////

#define MMGEM0_START		(IDMA_BASEADDR + 0x100)
#define MMGEM0_HEAD		(IDMA_BASEADDR + 0x104)
#define MMGEM0_LOCK		(IDMA_BASEADDR + 0x108)
#define MMGEM0_SRST		(IDMA_BASEADDR + 0x120)
#define GEM0MM_START		(IDMA_BASEADDR + 0x180)
#define GEM0MM_HEAD		(IDMA_BASEADDR + 0x184)
#define GEM0MM_LOCK		(IDMA_BASEADDR + 0x188)
#define GEM0MM_SRST		(IDMA_BASEADDR + 0x1A0)
#define MMGEM1_START		(IDMA_BASEADDR + 0x300)
#define MMGEM1_HEAD		(IDMA_BASEADDR + 0x304)
#define MMGEM1_LOCK		(IDMA_BASEADDR + 0x308)
#define MMGEM1_SRST		(IDMA_BASEADDR + 0x320)
#define GEM1MM_START		(IDMA_BASEADDR + 0x380)
#define GEM1MM_HEAD		(IDMA_BASEADDR + 0x384)
#define GEM1MM_LOCK		(IDMA_BASEADDR + 0x388)
#define GEM1MM_SRST		(IDMA_BASEADDR + 0x3A0)


////////////////////////////////////////////////////////////
// 	SPI block												    //
////////////////////////////////////////////////////////////

#define SPI_CTRLR0_REG		(SPI_BASEADDR+0x00)
#define SPI_CTRLR1_REG		(SPI_BASEADDR+0x04)
#define SPI_SSIENR_REG		(SPI_BASEADDR+0x08)
#define SPI_MWCR_REG		(SPI_BASEADDR+0x0c)
#define SPI_SER_REG		(SPI_BASEADDR+0x10)
#define SPI_BAUDR_REG		(SPI_BASEADDR+0x14)
#define SPI_TXFTLR_REG		(SPI_BASEADDR+0x18)
#define SPI_RXFTLR_REG		(SPI_BASEADDR+0x1c)
#define SPI_TXFLR_REG		(SPI_BASEADDR+0x20)
#define SPI_RXFLR_REG		(SPI_BASEADDR+0x24)
#define SPI_SR_REG		(SPI_BASEADDR+0x28)
#define SPI_IMR_REG		(SPI_BASEADDR+0x2c)
#define SPI_ISR_REG		(SPI_BASEADDR+0x30)
#define SPI_RISR_REG		(SPI_BASEADDR+0x34)
#define SPI_TXOICR_REG		(SPI_BASEADDR+0x38)
#define SPI_RXOICR_REG		(SPI_BASEADDR+0x3c)
#define SPI_RXUICR_REG		(SPI_BASEADDR+0x40)
#define SPI_MSTICR_REG		(SPI_BASEADDR+0x44)
#define SPI_ICR_REG		(SPI_BASEADDR+0x48)
#define SPI_IDR_REG		(SPI_BASEADDR+0x58)
#define SPI_DR_REG		(SPI_BASEADDR+0x60)

////////////////////////////////////////////////////////////
//	AHB block											    //
////////////////////////////////////////////////////////////
#define ASA_ARAM_PRI_REG	(ASA_ARAM_BASEADDR + 0x00)
#define ASA_ARAM_TC_REG		(ASA_ARAM_BASEADDR + 0x04)
#define ASA_ARAM_TC_CR_REG	(ASA_ARAM_BASEADDR + 0x08)
#define ASA_ARAM_STAT_REG	(ASA_ARAM_BASEADDR + 0x0C)

#define ASA_EBUS_PRI_REG	(ASA_EBUS_BASEADDR + 0x00)
#define ASA_EBUS_TC_REG		(ASA_EBUS_BASEADDR + 0x04)
#define ASA_EBUS_TC_CR_REG	(ASA_EBUS_BASEADDR + 0x08)
#define ASA_EBUS_STAT_REG	(ASA_EBUS_BASEADDR + 0x0C)

#define IDMA_MASTER		0
#define TDMA_MASTER		1
#define USBIPSEC_MASTER		2
#define ARM0_MASTER		3
#define ARM1_MASTER		4
#define MDMA_MASTER		5

#define IDMA_PRIORITY(level) (level)
#define TDM_PRIORITY(level) (level << 4)
#define USBIPSEC_PRIORITY(level) (level << 8)
#define ARM0_PRIORITY(level) (level << 12)
#define ARM1_PRIORITY(level) (level << 16)
#define MDMA_PRIORITY(level) (level << 20)

#define ASA_TC_REQIDMAEN	(1<<18)
#define ASA_TC_REQTDMEN		(1<<19)
#define ASA_TC_REQIPSECUSBEN	(1<<20)
#define ASA_TC_REQARM0EN	(1<<21)
#define ASA_TC_REQARM1EN	(1<<22)
#define ASA_TC_REQMDMAEN	(1<<23)

#define MEMORY_BASE_ADDR	0x80000000
#define MEMORY_MAX_ADDR		(ASD_BASEADDR + 0x10)
#define MEMORY_CR 		(ASD_BASEADDR + 0x14)
#define ROM_REMAP_EN		0x1

#define HAL_asb_priority(level) \
*(volatile unsigned *)ASA_PRI_REG = __cpu_to_le32(level)

#define HAL_aram_priority(level) \
*(volatile unsigned *)ASA_ARAM_PRI_REG = __cpu_to_le32(level)

#define HAL_aram_arbitration(arbitration_mask) \
*(volatile unsigned *)ASA_ARAM_TC_CR_REG |= __cpu_to_le32(arbitration_mask)

#define HAL_aram_defmaster(mask) \
*(volatile unsigned *)ASA_ARAM_TC_CR_REG = (*(volatile unsigned *)ASA_TC_CR_REG & __cpu_to_le32(0xFFFF)) | __cpu_to_le32(mask << 24)
////////////////////////////////////////////////////////////
// INTC block						  //
////////////////////////////////////////////////////////////

#define INTC_ARM1_CONTROL_REG	(INTC_BASEADDR + 0x18)



////////////////////////////////////////////////////////////
// TIMER block						  //
////////////////////////////////////////////////////////////

#define TIMER0_CNTR_REG		(TIMER_BASEADDR + 0x00)
#define TIMER0_CURR_COUNT	(TIMER_BASEADDR + 0x04)
#define TIMER1_CNTR_REG		(TIMER_BASEADDR + 0x08)
#define TIMER1_CURR_COUNT	(TIMER_BASEADDR + 0x0C)

#define TIMER2_CNTR_REG		(TIMER_BASEADDR + 0x18)
#define TIMER2_LBOUND_REG	(TIMER_BASEADDR + 0x10)
#define TIMER2_HBOUND_REG	(TIMER_BASEADDR + 0x14)
#define TIMER2_CURR_COUNT	(TIMER_BASEADDR + 0x1C)

#define TIMER3_LOBND		(TIMER_BASEADDR + 0x20)
#define TIMER3_HIBND		(TIMER_BASEADDR + 0x24)
#define TIMER3_CTRL		(TIMER_BASEADDR + 0x28)
#define TIMER3_CURR_COUNT	(TIMER_BASEADDR + 0x2C)

#define TIMER_MASK		(TIMER_BASEADDR + 0x40)
#define TIMER_STATUS		(TIMER_BASEADDR + 0x50)
#define TIMER_ACK		(TIMER_BASEADDR + 0x50)
#define TIMER_WDT_HIGH_BOUND	(TIMER_BASEADDR + 0xD0)
#define TIMER_WDT_CONTROL	(TIMER_BASEADDR + 0xD4)


////////////////////////////////////////////////////////////
//  EBUS block											    //
////////////////////////////////////////////////////////////

#define EX_SWRST_REG		(EBUS_BASEADDR + 0x00)
#define EX_CSEN_REG		(EBUS_BASEADDR + 0x04)
#define EX_CS0_SEG_REG		(EBUS_BASEADDR + 0x08)
#define EX_CS1_SEG_REG		(EBUS_BASEADDR + 0x0C)
#define EX_CS2_SEG_REG		(EBUS_BASEADDR + 0x10)
#define EX_CS3_SEG_REG		(EBUS_BASEADDR + 0x14)
#define EX_CS4_SEG_REG		(EBUS_BASEADDR + 0x18)
#define EX_CS0_CFG_REG		(EBUS_BASEADDR + 0x1C)
#define EX_CS1_CFG_REG		(EBUS_BASEADDR + 0x20)
#define EX_CS2_CFG_REG		(EBUS_BASEADDR + 0x24)
#define EX_CS3_CFG_REG		(EBUS_BASEADDR + 0x28)
#define EX_CS4_CFG_REG		(EBUS_BASEADDR + 0x2C)
#define EX_CS0_TMG1_REG		(EBUS_BASEADDR + 0x30)
#define EX_CS1_TMG1_REG		(EBUS_BASEADDR + 0x34)
#define EX_CS2_TMG1_REG		(EBUS_BASEADDR + 0x38)
#define EX_CS3_TMG1_REG		(EBUS_BASEADDR + 0x3C)
#define EX_CS4_TMG1_REG		(EBUS_BASEADDR + 0x40)
#define EX_CS0_TMG2_REG		(EBUS_BASEADDR + 0x44)
#define EX_CS1_TMG2_REG		(EBUS_BASEADDR + 0x48)
#define EX_CS2_TMG2_REG		(EBUS_BASEADDR + 0x4C)
#define EX_CS3_TMG2_REG		(EBUS_BASEADDR + 0x50)
#define EX_CS4_TMG2_REG		(EBUS_BASEADDR + 0x54)
#define EX_CS0_TMG3_REG		(EBUS_BASEADDR + 0x58)
#define EX_CS1_TMG3_REG		(EBUS_BASEADDR + 0x5C)
#define EX_CS2_TMG3_REG		(EBUS_BASEADDR + 0x60)
#define EX_CS3_TMG3_REG		(EBUS_BASEADDR + 0x64)
#define EX_CS4_TMG3_REG		(EBUS_BASEADDR + 0x68)
#define EX_CLOCK_DIV_REG	(EBUS_BASEADDR + 0x6C)
#define EX_MFSM_REG		(EBUS_BASEADDR + 0x100)
#define EX_CSFSM_REG		(EBUS_BASEADDR + 0x104)
#define EX_WRFSM_REG		(EBUS_BASEADDR + 0x108)
#define EX_RDFSM_REG		(EBUS_BASEADDR + 0x10C)

#define EX_CLK_EN		0x00000001
#define EX_CSBOOT_EN		0x00000002
#define EX_CS0_EN		0x00000002
#define EX_CS1_EN		0x00000004
#define EX_CS2_EN		0x00000008
#define EX_CS3_EN		0x00000010
#define EX_CS4_EN		0x00000020

#define EX_MEM_BUS_8		0x00000000
#define EX_MEM_BUS_16		0x00000002
#define EX_MEM_BUS_32		0x00000004
#define EX_CS_HIGH		0x00000008
#define EX_WE_HIGH		0x00000010
#define EX_RE_HIGH		0x00000020
#define EX_ALE_MODE		0x00000040
#define EX_STRB_MODE		0x00000080
#define EX_DM_MODE		0x00000100
#define EX_NAND_MODE		0x00000200
#define EX_RDY_EN		0x00000400
#define EX_RDY_EDGE		0x00000800


////////////////////////////////////////////////////////////
//  GPIO block												     //
////////////////////////////////////////////////////////////

#define GPIO_OUTPUT_REG		(GPIO_BASEADDR + 0x00)	// GPIO outputs register
#define GPIO_OE_REG		(GPIO_BASEADDR + 0x04)	// GPIO Output Enable register
#define GPIO_HI_INT_ENABLE_REG	(GPIO_BASEADDR + 0x08)
#define GPIO_LO_INT_ENABLE_REG	(GPIO_BASEADDR + 0x0C)
#define GPIO_INPUT_REG		(GPIO_BASEADDR + 0x10)	// GPIO input register
#define APB_ACCESS_WS_REG	(GPIO_BASEADDR + 0x14)
#define MUX_CONF_REG		(GPIO_BASEADDR + 0x18)
#define SYSCONF_REG		(GPIO_BASEADDR + 0x1C)
#define GPIO_ARM_ID_REG		(GPIO_BASEADDR + 0x30)
#define GPIO_BOOTSTRAP_REG	(GPIO_BASEADDR + 0x40)
#define GPIO_LOCK_REG		(GPIO_BASEADDR + 0x38)
#define GPIO_IOCTRL_REG		(GPIO_BASEADDR + 0x44)
#define GPIO_DEVID_REG		(GPIO_BASEADDR + 0x50)

#define GPIO_IOCTRL_A15A16	0x00000001
#define GPIO_IOCTRL_A17A18	0x00000002
#define GPIO_IOCTRL_A19A21	0x00000004
#define GPIO_IOCTRL_TMREVT0	0x00000008
#define GPIO_IOCTRL_TMREVT1	0x00000010
#define GPIO_IOCTRL_GPBT3	0x00000020
#define GPIO_IOCTRL_I2C		0x00000040
#define GPIO_IOCTRL_UART0	0x00000080
#define GPIO_IOCTRL_UART1	0x00000100
#define GPIO_IOCTRL_SPI		0x00000200
#define GPIO_IOCTRL_HBMODE	0x00000400

#define GPIO_IOCTRL_VAL		0x55555555

#define GPIO_0			0x01
#define GPIO_1			0x02
#define GPIO_2			0x04
#define GPIO_3			0x08
#define GPIO_4			0x10
#define GPIO_5			0x20
#define GPIO_6			0x40
#define GPIO_7			0x80

#define GPIO_RISING_EDGE	1
#define GPIO_FALLING_EDGE	2
#define GPIO_BOTH_EDGES		3


////////////////////////////////////////////////////////////
// UART													    //
////////////////////////////////////////////////////////////

#define UART_RBR		(UART_BASEADDR + 0x00)
#define UART_THR		(UART_BASEADDR + 0x00)
#define UART_DLL		(UART_BASEADDR + 0x00)
#define UART_IER		(UART_BASEADDR + 0x04)
#define UART_DLH		(UART_BASEADDR + 0x04)
#define UART_IIR		(UART_BASEADDR + 0x08)
#define UART_FCR		(UART_BASEADDR + 0x08)
#define UART_LCR		(UART_BASEADDR + 0x0C)
#define UART_MCR		(UART_BASEADDR + 0x10)
#define UART_LSR		(UART_BASEADDR + 0x14)
#define UART_MSR		(UART_BASEADDR + 0x18)
#define UART_SCR		(UART_BASEADDR + 0x1C)

////////////////////////////////////////////////////////////
// CLK  + RESET block 
////////////////////////////////////////////////////////////

#define CLKCORE_ARM_CLK_CNTRL	(CLKCORE_BASEADDR + 0x00)
#define CLKCORE_AHB_CLK_CNTRL	(CLKCORE_BASEADDR + 0x04)
#define CLKCORE_PLL_STATUS	(CLKCORE_BASEADDR + 0x08)
#define CLKCORE_CLKDIV_CNTRL	(CLKCORE_BASEADDR + 0x0C)
#define CLKCORE_TDM_CLK_CNTRL	(CLKCORE_BASEADDR + 0x10)
#define CLKCORE_FSYNC_CNTRL	(CLKCORE_BASEADDR + 0x14)
#define CLKCORE_CLK_PWR_DWN	(CLKCORE_BASEADDR + 0x18)
#define CLKCORE_RNG_CNTRL	(CLKCORE_BASEADDR + 0x1C)
#define CLKCORE_RNG_STATUS	(CLKCORE_BASEADDR + 0x20)
#define CLKCORE_ARM_CLK_CNTRL2	(CLKCORE_BASEADDR + 0x24)
#define CLKCORE_TDM_REF_DIV_RST	(CLKCORE_BASEADDR + 0x40)

#define ARM_PLL_BY_CTRL		0x80000000
#define ARM_AHB_BYP		0x04000000
#define PLL_DISABLE		0x02000000
#define PLL_CLK_BYPASS		0x01000000

#define AHB_PLL_BY_CTRL		0x80000000
#define DIV_BYPASS		0x40000000
#define SYNC_MODE		0x20000000

#define EPHY_CLKDIV_BYPASS	0x00200000
#define EPHY_CLKDIV_RATIO_SHIFT	16
#define PUI_CLKDIV_BYPASS	0x00004000
#define PUI_CLKDIV_SRCCLK	0x00002000
#define PUI_CLKDIV_RATIO_SHIFT	8
#define PCI_CLKDIV_BYPASS	0x00000020
#define PCI_CLKDIV_RATIO_SHIFT	0

#define ARM0_CLK_PD		0x00200000
#define ARM1_CLK_PD		0x00100000
#define EPHY_CLK_PD		0x00080000
#define TDM_CLK_PD		0x00040000
#define PUI_CLK_PD		0x00020000
#define PCI_CLK_PD		0x00010000
#define MDMA_AHBCLK_PD		0x00000400
#define I2CSPI_AHBCLK_PD	0x00000200
#define UART_AHBCLK_PD		0x00000100
#define IPSEC_AHBCLK_PD		0x00000080
#define TDM_AHBCLK_PD		0x00000040
#define USB1_AHBCLK_PD		0x00000020
#define USB0_AHBCLK_PD		0x00000010
#define GEMAC1_AHBCLK_PD	0x00000008
#define GEMAC0_AHBCLK_PD	0x00000004
#define PUI_AHBCLK_PD		0x00000002
#define HIF_AHBCLK_PD		0x00000001

#define ARM1_DIV_BP		0x00001000
#define ARM1_DIV_VAL_SHIFT	8
#define ARM0_DIV_BP		0x00000010
#define ARM0_DIV_VAL_SHIFT	0

#define AHBCLK_PLL_LOCK		0x00000002
#define FCLK_PLL_LOCK		0x00000001


// reset block
#define BLOCK_RESET_REG		(CLKCORE_BASEADDR + 0x100)
#define CSP_RESET_REG		(CLKCORE_BASEADDR + 0x104)

#define RNG_RST			0x1000
#define IPSEC_RST		0x0800
#define DDR_RST			0x0400
#define USB1_PHY_RST		0x0200
#define USB0_PHY_RST		0x0100
#define USB1_RST		0x0080
#define USB0_RST		0x0040
#define GEMAC1_RST		0x0020
#define GEMAC0_RST		0x0010
#define TDM_RST			0x0008
#define PUI_RST			0x0004
#define HIF_RST			0x0002
#define PCI_RST			0x0001

////////////////////////////////////////////////////////////////
//	DDR  CONTROLLER block
////////////////////////////////////////////////////////////////

#define DDR_CONFIG_BASEADDR	0x0D000000
#define DENALI_CTL_00_DATA	(DDR_CONFIG_BASEADDR + 0x00)
#define DENALI_CTL_01_DATA	(DDR_CONFIG_BASEADDR + 0x08)
#define DENALI_CTL_02_DATA	(DDR_CONFIG_BASEADDR + 0x10)
#define DENALI_CTL_03_DATA	(DDR_CONFIG_BASEADDR + 0x18)
#define DENALI_CTL_04_DATA	(DDR_CONFIG_BASEADDR + 0x20)
#define DENALI_CTL_05_DATA	(DDR_CONFIG_BASEADDR + 0x28)
#define DENALI_CTL_06_DATA	(DDR_CONFIG_BASEADDR + 0x30)
#define DENALI_CTL_07_DATA	(DDR_CONFIG_BASEADDR + 0x38)
#define DENALI_CTL_08_DATA	(DDR_CONFIG_BASEADDR + 0x40)
#define DENALI_CTL_09_DATA	(DDR_CONFIG_BASEADDR + 0x48)
#define DENALI_CTL_10_DATA	(DDR_CONFIG_BASEADDR + 0x50)
#define DENALI_CTL_11_DATA	(DDR_CONFIG_BASEADDR + 0x58)
#define DENALI_CTL_12_DATA	(DDR_CONFIG_BASEADDR + 0x60)
#define DENALI_CTL_13_DATA	(DDR_CONFIG_BASEADDR + 0x68)
#define DENALI_CTL_14_DATA	(DDR_CONFIG_BASEADDR + 0x70)
#define DENALI_CTL_15_DATA	(DDR_CONFIG_BASEADDR + 0x78)
#define DENALI_CTL_16_DATA	(DDR_CONFIG_BASEADDR + 0x80)
#define DENALI_CTL_17_DATA	(DDR_CONFIG_BASEADDR + 0x88)
#define DENALI_CTL_18_DATA	(DDR_CONFIG_BASEADDR + 0x90)
#define DENALI_CTL_19_DATA	(DDR_CONFIG_BASEADDR + 0x98)
#define DENALI_CTL_20_DATA	(DDR_CONFIG_BASEADDR + 0xA0)

#define DENALI_READY_CHECK         *((volatile u32 *) (DDR_CONFIG_BASEADDR + 0x44))
#define DENALI_WR_DQS               *((volatile u8 *)  (DDR_CONFIG_BASEADDR + 0x5D))
#define DENALI_DQS_OUT             *((volatile u8 *) (DDR_CONFIG_BASEADDR + 0x5A))
#define DENALI_DQS_DELAY0      *((volatile u8 *) (DDR_CONFIG_BASEADDR + 0x4F))
#define DENALI_DQS_DELAY1      *((volatile u8 *)  (DDR_CONFIG_BASEADDR +0x50))
#define DENALI_DQS_DELAY2      *((volatile u8 *)  (DDR_CONFIG_BASEADDR +0x51))
#define DENALI_DQS_DELAY3       *((volatile u8 *)  (DDR_CONFIG_BASEADDR +0x52))


//DENALI CONFIGRATION FOR BOARD CONFIG #1
#define DENALI_CTL_00_VAL_CFG1	0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG1	0x0100000100000001LL
#define DENALI_CTL_02_VAL_CFG1	0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG1	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG1	0x0000010100000001LL
#define DENALI_CTL_05_VAL_CFG1	0x0203010300000101LL
#define DENALI_CTL_06_VAL_CFG1	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG1	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG1	0x6400003f3f0a0200LL
#define DENALI_CTL_09_VAL_CFG1	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG1	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG1	0x433a34124a650a00LL
#define DENALI_CTL_12_VAL_CFG1	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG1	0x0010002000100080LL	
#define DENALI_CTL_14_VAL_CFG1	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG1	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG1	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG1	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG1	0x0302000000000000LL
#define DENALI_CTL_19_VAL_CFG1	0x00001400c8030600LL
#define DENALI_CTL_20_VAL_CFG1	0x00000000823600c8LL


//DENALI CONFIGRATION FOR BOARD CONFIG #2
#define DENALI_CTL_00_VAL_CFG2	0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG2	0x0100010100000001LL
#define DENALI_CTL_02_VAL_CFG2	0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG2	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG2	0x0000010200000003LL 
#define DENALI_CTL_05_VAL_CFG2	0x0203010300000101LL
#define DENALI_CTL_06_VAL_CFG2	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG2	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG2	0x6400003f3f0a0207LL
#define DENALI_CTL_09_VAL_CFG2	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG2	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG2	0x433a34164a650a00LL
#define DENALI_CTL_12_VAL_CFG2	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG2	0x0010002000100080LL
#define DENALI_CTL_14_VAL_CFG2	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG2	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG2	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG2	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG2	0x0302000000000000LL
#define DENALI_CTL_19_VAL_CFG2	0x00001700c8030600LL
#define DENALI_CTL_20_VAL_CFG2	0x00000000423600c8LL


//DENALI CONFIGRATION FOR BOARD CONFIG #3
#define DENALI_CTL_00_VAL_CFG3	0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG3	0x0100010100000001LL
#define DENALI_CTL_02_VAL_CFG3	0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG3	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG3	0x0000010200000003LL 
#define DENALI_CTL_05_VAL_CFG3	0x0203010300000101LL
#define DENALI_CTL_06_VAL_CFG3	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG3	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG3	0x6400003f3f0a0207LL
#define DENALI_CTL_09_VAL_CFG3	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG3	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG3	0x433a34164a650a00LL
#define DENALI_CTL_12_VAL_CFG3	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG3	0x0010002000100080LL
#define DENALI_CTL_14_VAL_CFG3	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG3	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG3	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG3	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG3	0x0302000000000000LL
#define DENALI_CTL_19_VAL_CFG3	0x00001700c8030600LL
#define DENALI_CTL_20_VAL_CFG3	0x00000000423600c8LL


//DENALI CONFIGRATION FOR BOARD CONFIG #4
#define DENALI_CTL_00_VAL_CFG4	0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG4	0x0100000100000001LL
#define DENALI_CTL_02_VAL_CFG4	0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG4	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG4	0x0000010100000001LL
#define DENALI_CTL_05_VAL_CFG4	0x0203010300010101LL
#define DENALI_CTL_06_VAL_CFG4	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG4	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG4	0x6400003f3f0a0200LL
#define DENALI_CTL_09_VAL_CFG4	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG4	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG4	0x433a34124a650a00LL
#define DENALI_CTL_12_VAL_CFG4	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG4	0x0010002000100080LL
#define DENALI_CTL_14_VAL_CFG4	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG4	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG4	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG4	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG4	0x0302000000000000LL
#define DENALI_CTL_19_VAL_CFG4	0x00001400c8030600LL
#define DENALI_CTL_20_VAL_CFG4	0x00000000423600c8LL


//DENALI CONFIGRATION FOR BOARD CONFIG #5
#define DENALI_CTL_00_VAL_CFG5	0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG5	0x0100000100000001LL
#define DENALI_CTL_02_VAL_CFG5	0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG5	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG5	0x0000010100000001LL
#define DENALI_CTL_05_VAL_CFG5	0x0203020300010101LL
#define DENALI_CTL_06_VAL_CFG5	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG5	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG5	0x6400003f3f0a0200LL
#define DENALI_CTL_09_VAL_CFG5	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG5	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG5	0x433a340d4a650a00LL
#define DENALI_CTL_12_VAL_CFG5	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG5	0x0010002000100080LL
#define DENALI_CTL_14_VAL_CFG5	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG5	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG5	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG5	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG5	0x0302000000000000LL
#define DENALI_CTL_19_VAL_CFG5	0x00000f00c8030600LL
#define DENALI_CTL_20_VAL_CFG5	0x00000000423600c8LL


//DENALI CONFIGRATION FOR BOARD CONFIG #6
#define DENALI_CTL_00_VAL_CFG6	0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG6	0x0100000100000001LL
#define DENALI_CTL_02_VAL_CFG6	0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG6	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG6	0x0000010200000001LL
#define DENALI_CTL_05_VAL_CFG6	0x0203010300000101LL
#define DENALI_CTL_06_VAL_CFG6	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG6	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG6	0x6400003f3f0a0200LL
#define DENALI_CTL_09_VAL_CFG6	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG6	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG6	0x433a34124a650a00LL
#define DENALI_CTL_12_VAL_CFG6	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG6	0x0010002000100080LL	
#define DENALI_CTL_14_VAL_CFG6	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG6	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG6	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG6	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG6	0x0302000000000000LL
#define DENALI_CTL_19_VAL_CFG6	0x00001400c8030600LL
#define DENALI_CTL_20_VAL_CFG6	0x00000000423600c8LL


/* For 125 MHz AHB clock speed for CONFIG #9 (Similar to Config #4) */
#define DENALI_CTL_07_VAL_CFG4_C50      0x0000000200000206LL
#define DENALI_CTL_08_VAL_CFG4_C50      0x6400003f3f070200LL
#define DENALI_CTL_11_VAL_CFG4_C50      0x323a340e4a650a00LL
#define DENALI_CTL_12_VAL_CFG4_C50      0x0000000000000500LL
#define DENALI_CTL_15_VAL_CFG4_C50      0x03c8000000000000LL
#define DENALI_CTL_16_VAL_CFG4_C50      0x0000000022240000LL
#define DENALI_CTL_18_VAL_CFG4_C50      0x0202000001000000LL
#define DENALI_CTL_19_VAL_CFG4_C50      0x00000f00c8020400LL
#define DENALI_CTL_20_VAL_CFG4_C50      0x0000000061a800c8LL

/* DENALI CONFIGRATION FOR BOARD CONFIG #10
 * C50 Router Board */
#define DENALI_CTL_00_VAL_CFG10		0x0100000101010101LL
#define DENALI_CTL_01_VAL_CFG10		0x0100010100000001LL /* EIGHT_BANK_MODE[40]=0x1 */
#define DENALI_CTL_02_VAL_CFG10		0x0100010000010100LL
#define DENALI_CTL_03_VAL_CFG10 	0x0102020202020201LL
#define DENALI_CTL_04_VAL_CFG10 	0x0000010100000001LL
#define DENALI_CTL_05_VAL_CFG10 	0x0203010300010101LL
#define DENALI_CTL_06_VAL_CFG10 	0x060a020200020202LL
#define DENALI_CTL_07_VAL_CFG10 	0x0000000300000206LL
#define DENALI_CTL_08_VAL_CFG10 	0x6400003f3f0a0207LL /* TFAW [0:4]=0x7 */
#define DENALI_CTL_09_VAL_CFG10 	0x1700000000000000LL
#define DENALI_CTL_10_VAL_CFG10 	0x0120202020191a18LL
#define DENALI_CTL_11_VAL_CFG10 	0x433a34104a650a00LL /* TRFC [39:32]=0x10 */
#define DENALI_CTL_12_VAL_CFG10 	0x0000000000000700LL
#define DENALI_CTL_13_VAL_CFG10 	0x0010002000100080LL
#define DENALI_CTL_14_VAL_CFG10 	0x0010004000100040LL
#define DENALI_CTL_15_VAL_CFG10 	0x050e000000000000LL
#define DENALI_CTL_16_VAL_CFG10 	0x000000002d890000LL
#define DENALI_CTL_17_VAL_CFG10 	0x0000000000000000LL
#define DENALI_CTL_18_VAL_CFG10 	0x0302000001000000LL /* REDUC [24]= 0x1 */
#define DENALI_CTL_19_VAL_CFG10 	0x00001200c8030600LL /* TXSNR [55:40]=0x12 */
#define DENALI_CTL_20_VAL_CFG10 	0x00000000423600c8LL


#define WRITE_VAL_U8                   *((volatile u8 *)   0x80000000)
#define WRITE_VAL_U16                 *((volatile u16 *)  0x80000000)
#define WRITE_VAL_U32                 *((volatile u32 *)  0x80000000)
#define WRITE_VAL_U64                 *((volatile u64 *)  0x80000000)

#define AHB_MAX_MEM_REG                *((volatile u64 *)  0x10060010)

#define REDUC                          *((volatile u64 *)(DDR_CONFIG_BASEADDR +  0x90))
#define CS_MAP                         *((volatile u64 *)(DDR_CONFIG_BASEADDR +0x20))

#define BOARD_MASK 0x1C00
#define BOARD1     1024
#define BOARD2     2048
#define BOARD3     3072
#define BOARD4     4096
#define BOARD5     5120
#define BOARD6     6144
    
#define LOW_WR_DQS        0x3A //0x20
#define HIGH_WR_DQS       0x50 //0x80

#define LOW_DQS_OUT       0x60 //0x55
#define HIGH_DQS_OUT      0x70 //0x75

#define LOW_RD0           0x10
#define HIGH_RD0          0x25
#define LOW_RD1           0x10
#define HIGH_RD1          0x25
#define LOW_RD2           0x10
#define HIGH_RD2          0x25
#define LOW_RD3           0x10
#define HIGH_RD3          0x25


#define LOW_DQS_DELAY0    0x10
#define HIGH_DQS_DELAY0   0x25

#define LOW_DQS_DELAY1    0x10
#define HIGH_DQS_DELAY1   0x25

#define LOW_DQS_DELAY2    0x10
#define HIGH_DQS_DELAY2   0x25

#define LOW_DQS_DELAY3    0x10
#define HIGH_DQS_DELAY3   0x25

#endif

/* end of file comcerto_1xx.h */
