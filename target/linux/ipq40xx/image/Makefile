# Copyright (c) 2014 The Linux Foundation. All rights reserved.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

UBIFS_OPTS = -m 2048 -e 124KiB -c 4096 -U -F
UBI_OPTS = -m 2048 -p 128KiB

E2SIZE=$(shell echo $$(($(CONFIG_TARGET_ROOTFS_PARTSIZE)*1024)))
ZYXEL_BIN_DIR=$(BIN_DIR)/zyxel

define Image/BuildKernel/FIT
	$(CP) $(KDIR)/Image $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.bin
	gzip -9 -c $(KDIR)/Image > $(KDIR)/Image.gz
	$(call CompressLzma,$(KDIR)/Image,$(KDIR)/Image.gz)
ifeq ($(3),compressed-dtb)
	gzip -9 -c $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb > $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb.gz
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image.gz, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb.gz,gzip,$(2),$(2),,$(4))
else
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image.gz, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb,gzip,$(2),$(2))
endif
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage.itb
	$(CP) $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb $(BIN_DIR)/$(IMG_PREFIX)-$(1).dtb
ifneq ($(CONFIG_TARGET_ROOTFS_INITRAMFS),)
	$(CP) $(KDIR)/Image-initramfs $(BIN_DIR)/$(IMG_PREFIX)-vmlinux-initramfs.bin
	$(call Image/BuildKernel/MkFIT,$(1), $(KDIR)/Image-initramfs, $(LINUX_DIR)/arch/arm/boot/dts/$(1).dtb, none,$(2),$(2))
	$(CP) $(KDIR)/fit-$(1).itb $(BIN_DIR)/$(IMG_PREFIX)-$(1)-fit-uImage-initramfs.itb
endif
endef

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

define Image/BuildKernel
	$(CP) $(KDIR)/vmlinux $(BIN_DIR)/$(IMG_PREFIX)-vmlinux.elf
	$(CP) $(LINUX_DIR)/arch/arm/boot/Image $(KDIR)/Image
	$(call Image/BuildKernel/FIT,qcom-ipq40xx-nbg6617,0x80208000)
endef

define Image/Build/squashfs
	$(call prepare_generic_squashfs,$(KDIR)/root.squashfs)
endef

define Image/Build
	$(call Image/Build/$(1),$(1))
	dd if=$(KDIR)/root$(2).$(1) of=$(BIN_DIR)/$(IMG_PREFIX)$(2)-$(1)-root.img bs=128k conv=sync
	mkdir -p $(ZYXEL_BIN_DIR)
	if [ -e $(BIN_DIR)/$(IMG_PREFIX)-$(1)-root.img ]; then \
                $(CP) $(BIN_DIR)/$(IMG_PREFIX)$(2)-$(1)-root.img $(ZYXEL_BIN_DIR)/$(shell echo $(BOARDNAME) | tr A-Z a-z)-rootfs.squashfs; \
        fi
	$(CP) $(BIN_DIR)/$(IMG_PREFIX)-qcom-ipq40xx-nbg6617-fit-uImage.itb $(ZYXEL_BIN_DIR)/$(shell echo $(BOARDNAME) | tr A-Z a-z)-vmlinux$(COMPRESSION_SUFFIX).uImage
endef

$(eval $(call BuildImage))
