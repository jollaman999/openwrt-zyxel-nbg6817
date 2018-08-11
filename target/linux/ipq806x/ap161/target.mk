ARCH:=arm
#----------- Configuration
include $(INCLUDE_DIR)/kernel.mk
#----------- End of configuration

BOARDNAME:=AP161

define Target/Description
	Build firmware images for AP161 board.
endef
