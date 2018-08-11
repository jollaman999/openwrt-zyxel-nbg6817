include $(TOPDIR)/rules.mk

# Build package version from git sha-1
PKG_NAME:=lil-ozker
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=ssh://qca-git01.qualcomm.com:29418/streamboost/lil-ozker
PKG_BRANCH:=banana
PKG_START_ORDER:=59
PKG_RELEASE:=2

include $(INCLUDE_DIR)/local-development.mk
ifeq ($(DUMP)$(PKG_VERSION),)
PKG_REV:=854699a
PKG_VERSION:=g854699a
endif

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=$(PKG_REV)
PKG_SOURCE_MIRROR:=none
PKG_BUILD_DEPENDS:=jansson argp-standalone
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package-version-override.mk
include $(INCLUDE_DIR)/package.mk

# use SPACES here instead of tabs
define Package/$(PKG_NAME)/Default
  CATEGORY:=Bigfoot
  SUBMENU:=Web UI
  TITLE:=FastCGI Gateway for the Web UI - Slim Version
  DEPENDS:=+jansson +fcgi +libsbdaemon
  MAINTAINER:=Cristian Prundeanu <prundeanu@qca.qualcomm.com>
endef

define Package/$(PKG_NAME)
$(call Package/$(PKG_NAME)/Default)
  VARIANT:=fcgi
endef

# The "nofcgi" variant still uses FastCGI, but communicates with the http server
# via the cgi-fcgi shim
define Package/$(PKG_NAME)-nofcgi
$(call Package/$(PKG_NAME)/Default)
  VARIANT:=nofcgi
  PROVIDES:=$(PKG_NAME)
endef

define Package/$(PKG_NAME)/description
Lil ozKer is ozKer's baby daemon. He does the same job as his daddy,
providing an interface between the UI and the information scattered
everywhere in the system, except he's much slimmer.
endef

define Package/$(PKG_NAME)-nofcgi/description
$(call Package/$(PKG_NAME)/description)

This variant works with http servers which don't have FCGI support.
endef

# https://forum.openwrt.org/viewtopic.php?id=21953
TARGET_CFLAGS += -Wl,-rpath-link=$(STAGING_DIR)/usr/lib

# use TABs here instead of spaces if you need to break up a long line
MAKE_FLAGS += \
	EXTRA_LDLIBS+="-largp"


# use TABs here instead of spaces
define Package/$(PKG_NAME)-nofcgi/install
	$(INSTALL_DIR) $(1)/etc/appflow/streamboost.d/
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/$(PKG_NAME) $(1)/usr/sbin/
	$(INSTALL_BIN) ./files/$(PKG_NAME).init $(1)/etc/appflow/streamboost.d/$(PKG_START_ORDER)_$(PKG_NAME)
endef

define Package/$(PKG_NAME)/install
$(call Package/$(PKG_NAME)-nofcgi/install,$(1))
	$(INSTALL_DIR) $(1)/www/cgi-bin/
	$(INSTALL_BIN) ./files/$(PKG_NAME).cgiwrapper $(1)/www/cgi-bin/$(PKG_NAME)
endef


# NO TABS, NO SPACES
$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-nofcgi))
