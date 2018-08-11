include $(TOPDIR)/rules.mk

PKG_NAME=zyxel-streamboost
PKG_VERSION=1
PKG_RELEASE=1

include $(INCLUDE_DIR)/package.mk

define Package/zyxel-streamboost
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Modify streamboost configuration files for zyxel devices
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) -a ./files/* $(1)/
ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"nbg6815")
	$(CP) -a ./files_nbg6815/* $(1)/
else ifeq ($(CONFIG_UBOOT_ZYXEL_TARGET),"nbg6816")
	$(CP) -a ./files_nbg6816/* $(1)/
else
	$(CP) -a ./files_nbg6817/* $(1)/
endif

endef

$(eval $(call BuildPackage,zyxel-streamboost))
