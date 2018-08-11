ARCH:=arm
CPU_TYPE:=cortex-a7
#----------- Configuration
include $(INCLUDE_DIR)/kernel.mk
#----------- End of configuration

BOARDNAME:=NBG6617

define Target/Description
	Build firmware images for NBG6617 board.
endef
