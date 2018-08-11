ARCH:=arm
#----------- Configuration
include $(INCLUDE_DIR)/kernel.mk
#----------- End of configuration

BOARDNAME:=NBG6817

define Target/Description
	Build firmware images for NBG6817 board.
endef
