# Copyright (c) 2013 The Linux Foundation. All rights reserved.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

UBIFS_OPTS = -m 2048 -e 124KiB -c 4096 -U -F
UBINIZE_OPTS = -m 2048 -p 128KiB

E2SIZE=$(shell echo $$(($(CONFIG_TARGET_ROOTFS_PARTSIZE)*1024)))
ZYXEL_BIN_DIR=$(BIN_DIR)/zyxel
define Image/BuildKernel
	$(CP) $(LINUX_DIR)/vmlinux $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.elf
	$(CP) $(LINUX_DIR)/arch/arm/boot/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	dd if=$(LINUX_DIR)/arch/arm/boot/uImage of=$(KERNEL_BUILD_DIR)/uImage bs=2k conv=sync
	$(CP) $(KERNEL_BUILD_DIR)/uImage $(BIN_DIR)/$(IMG_PREFIX)-$(KERNEL)-uImage
endef

define Image/Build
	$(call Image/Build/$(1),$(1))
	mkdir -p $(BIN_DIR)
	dd if=$(KDIR)/root.$(1) of=$(BIN_DIR)/$(IMG_PREFIX)-$(1)-root.img bs=2k conv=sync
	mkdir -p $(ZYXEL_BIN_DIR)
	if [ -e $(BIN_DIR)/$(IMG_PREFIX)-$(1)-root.img ]; then \
		$(CP) $(BIN_DIR)/$(IMG_PREFIX)-$(1)-root.img $(ZYXEL_BIN_DIR)/$(shell echo $(BOARDNAME) | tr A-Z a-z)-rootfs.squashfs; \
	fi
	$(CP) $(BIN_DIR)/$(IMG_PREFIX)-$(KERNEL)-uImage $(ZYXEL_BIN_DIR)/$(shell echo $(BOARDNAME) | tr A-Z a-z)-vmlinux$(COMPRESSION_SUFFIX).uImage
endef

#define Sysupgrade
#	$(CP) ./sysupgrade-$(1).its $(BIN_DIR)/$(IMG_PREFIX)-sysupgrade-$(1).its
#	PATH=$$PATH:$(LINUX_DIR)/scripts/dtc $(STAGING_DIR_HOST)/bin/mkimage \
#		-f $(BIN_DIR)/$(IMG_PREFIX)-sysupgrade-$(1).its \
#		$(BIN_DIR)/$(IMG_PREFIX)-sysupgrade-$(1).bin
#endef

#define Sysupgrade/ubi
#	$(call Sysupgrade,ubi)
#endef

#define Sysupgrade/squashfs
#	$(call Sysupgrade,squashfs)
#endef
define zyxel_tools/genImageHeader
	@echo;echo "!!! my Generate $(shell grep "OUTPUT_NAME" $(FW_INFO_FILE)| cut -d '=' -f 2| tr -d \") FW !!!";echo
#	@echo;echo "!!! $(STAGING_DIR_HOST)/bin/genImgHdr -i $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.squashfs -k $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-vmlinux.uImage -v $(shell grep "FW_VERSION" $(FW_INFO_FILE)| cut -d '=' -f 2) -p $(shell grep "PROJECT_NAME" $(FW_INFO_FILE)| cut -d '=' -f 2) -s $(if $(ZY_IMG_HDR_EXTEND_SIZE),$(ZY_IMG_HDR_EXTEND_SIZE),0x10000) -o ras.bin.squashfs.header&&cp ras.bin.squashfs.header ras.bin.squashfs&&cat $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.squashfs>>ras.bin.squashfs&&cat $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-vmlinux.uImage>>ras.bin.squashfs;!!!";echo
	@(cd $(BIN_DIR)/zyxel; \
	if [ ! -f $(FW_INFO_FILE) ]; then \
		echo "Not found file '$(FW_INFO_FILE)'"; \
		echo "*** [genImgHdr] Error"; \
		exit 1; \
	fi; \
	if [ -f $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.jffs2 ]; then \
		$(STAGING_DIR_HOST)/bin/genImgHdr -i $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.jffs2 -v $(shell grep "FW_VERSION" $(FW_INFO_FILE)| cut -d '=' -f 2) -p $(shell grep "PROJECT_NAME" $(FW_INFO_FILE)| cut -d '=' -f 2) -s $(if $(ZY_IMG_HDR_EXTEND_SIZE),$(ZY_IMG_HDR_EXTEND_SIZE),0x10000) -o ras.bin.jffs2.header&&cp ras.bin.jffs2.header ras.bin.jffs2&&cat $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.jffs2>>ras.bin.jffs2;\
	fi; \
	if [ -f $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.squashfs ]; then \
		$(STAGING_DIR_HOST)/bin/genImgHdr -i $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.squashfs -k $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-vmlinux.uImage -v $(shell grep "FW_VERSION" $(FW_INFO_FILE)| cut -d '=' -f 2) -p $(shell grep "PROJECT_NAME" $(FW_INFO_FILE)| cut -d '=' -f 2) -s $(if $(ZY_IMG_HDR_EXTEND_SIZE),$(ZY_IMG_HDR_EXTEND_SIZE),0x10000) -o ras.bin.squashfs.header&&cp ras.bin.squashfs.header ras.bin.squashfs&&cat $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-rootfs.squashfs>>ras.bin.squashfs&&cat $(BIN_DIR)/zyxel/$(ZY_IMG_PREFIX)-vmlinux.uImage>>ras.bin.squashfs; \
	fi)
endef

$(eval $(call BuildImage))
