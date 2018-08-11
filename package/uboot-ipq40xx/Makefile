#
# Copyright (c) 2014 The Linux Foundation. All rights reserved.
# Copyright (C) 2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/version.mk

PKG_NAME:=uboot-1.0
PKG_VERSION:=2012.07
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_PROTO:=git
PKG_BRANCH:=master
PKG_RELEASE:=1

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
  PKG_REV:=$(shell git ls-remote $(PKG_SOURCE_URL) $(PKG_BRANCH) | cut -b -7)
  PKG_VERSION:=g$(PKG_REV)
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)

include $(INCLUDE_DIR)/package.mk

define Package/uboot-ipq40xx
  SECTION:=boot
  CATEGORY:=Boot Loaders
  DEPENDS:=@TARGET_ipq40xx
  TITLE:=U-boot for ipq40xx  based platforms
  URL:=http://www.denx.de/wiki/U-Boot
endef


define Build/Prepare
	$(PKG_UNPACK)
	cp -r $(CP_OPTS) $(FILES_DIR)/* $(PKG_BUILD_DIR)/
	$(Build/Patch)
	find $(PKG_BUILD_DIR) -name .svn | $(XARGS) rm -rf
endef

UBOOT_ZYXEL_TARGET:=$(call qstrip,$(CONFIG_UBOOT_ZYXEL_TARGET))
UBOOT_MAX_SIZE:=$(if $(CONFIG_UBOOT_ZYXEL_MAXSIZE),$(CONFIG_UBOOT_ZYXEL_MAXSIZE),409600)

ifneq ($(CONFIG_EMBEDDED_KERNEL_IN_ROOTFS),)
        EMBEDDED_KERNEL_IN_ROOTFS:="CONFIG_EMBEDDED_KERNEL_IN_ROOTFS=y"
endif

ifneq ($(CONFIG_UBOOT_ZYXEL_SUPPORT_ZLOADER),)
        SUPPORT_ZLOADER:="CONFIG_ZLOADER_SUPPORTED=y"
endif

ifneq ($(CONFIG_UBOOT_ZYXEL_SUPPORT_ROMD),)
        SUPPORT_ROM_D:="CONFIG_ZLOADER_ROMD_SUPPORTED=y"
endif

ifneq ($(CONFIG_UBOOT_ZYXEL_SUPPORT_ROMFILE),)
        SUPPORT_ROMFILE:="CONFIG_ZLOADER_ROMFILE_SUPPORTED=y"
endif

UBOOT_MAKE_OPTS:= \
        CROSS_COMPILE=$(TARGET_CROSS) \
        $(EMBEDDED_KERNEL_IN_ROOTFS) \
        $(SUPPORT_ZLOADER) \
        $(SUPPORT_ROM_D) \
	$(SUPPORT_ROMFILE)

define Package/uboot-ipq40xx/config
	source "$(SOURCE)/Config.in"
endef

define Build/Configure/Target
	$(MAKE) -C $(PKG_BUILD_DIR)\
	$(UBOOT_MAKE_OPTS) \
	$(1)_config
endef

define Build/Configure
        $(call Build/Configure/Target,$(UBOOT_ZYXEL_TARGET))
endef

define Build/Compile
	VERSION_CODE='$(VERSION_NICK) $(VERSION_NUMBER)' \
	REVISION='$(REVISION)' \
	$(MAKE) -C $(PKG_BUILD_DIR) HOSTCC=$(TARGET_CC) \
		HOSTSTRIP=true CROSS_COMPILE=$(TARGET_CROSS) \
		QSDK_CFLAGS="$(TARGET_CFLAGS)" \
		QSDK_LDFLAGS="$(TARGET_LDFLAGS)" \
		$(UBOOT_MAKE_OPTS)
endef

ifneq ($(CONFIG_UBOOT_ZYXEL_SUPPORT_ZLOADER),)
define Build/InstallDev
# share standlone library for ZyBoot
	$(INSTALL_DIR) $(1)/usr/include/uboot-zyxel
	$(INSTALL_DIR) $(1)/usr/lib/uboot-zyxel
	$(TARGET_CROSS)ar -rcs $(1)/usr/lib/uboot-zyxel/libstubs.a $(PKG_BUILD_DIR)/examples/standalone/libstubs.o
	$(CP) -L -H $(PKG_BUILD_DIR)/include/* $(1)/usr/include/uboot-zyxel/
endef
endif

define Package/uboot-ipq40xx/install
	$(INSTALL_DIR) $(1)
	$(CP) $(PKG_BUILD_DIR)/u-boot $(BIN_DIR)/openwrt-$(BOARD)-u-boot.elf
	$(CP) $(PKG_BUILD_DIR)/u-boot $(BIN_DIR)/openwrt-$(BOARD)-u-boot-stripped.elf
	$(STRIP) $(BIN_DIR)/openwrt-$(BOARD)-u-boot-stripped.elf
	$(CP) $(PKG_BUILD_DIR)/u-boot.bin $(BIN_DIR)/openwrt-$(BOARD)-u-boot.img
endef


$(eval $(call BuildPackage,uboot-ipq40xx))
