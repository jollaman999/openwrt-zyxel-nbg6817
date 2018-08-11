include $(TOPDIR)/rules.mk

PKG_NAME:=accel-pptp
PKG_VERSION:=0.8.5
PKG_RELEASE:=3

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
#PKG_SOURCE_URL:=@SF/accel-pptp
PKG_MD5SUM:=061ca3991fb69e0e79cb872b0aaf1d89

PKG_SOURCE_URL:=$(SVN_REPOSITORY_ROOT)/openwrt/dl
PKG_SOURCE_PROTO:=svn_pkg
PKG_SOURCE_VERSION:=HEAD

PKG_PPP_VERSION:=2.4.7

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/accel-pptp
	SECTION:=net
	CATEGORY:=Network
	TITLE:=PPTP client
	URL:=http://pptpclient.sourceforge.net/
	DEPENDS:=ppp +libtool +kmod-pptp
	#DEPENDS:=+ppp +kmod-gre +kmod-pptp +resolveip +ip
endef

define Package/accel-pptp/description
	This package contains a PPTP (Point-to-Point Tunneling Protocol) client (kernel-accelerated version).
endef

define Package/accel-pptp/conffiles
/etc/ppp/options.pptp
endef

CONFIGURE_ARGS += --disable-static
CONFIGURE_VARS += \
	KDIR="$(LINUX_DIR)" \
	PPPD_VERSION="$(PKG_PPP_VERSION)" \

MAKE_OPTS+= \
	PPPD_SRCDIR="$(STAGING_DIR)/usr/include" \
	PPPD_LIBDIR="$(STAGING_DIR)/usr/lib" \
	PPPD_VERSION="$(PKG_PPP_VERSION)" \
	DESTDIR="$(PKG_INSTALL_DIR)"

# we patch configure.in, so do autoconf
define Build/Prepare
	$(call Build/Prepare/Default)
	autoreconf "$(PKG_BUILD_DIR)/pppd_plugin"
endef

define Build/Configure
	$(call Build/Configure/Default,,,pppd_plugin)
endef

define Build/Compile
	(cd $(PKG_BUILD_DIR)/pppd_plugin ; \
	$(MAKE) $(MAKE_OPTS) ; \
	$(MAKE) $(MAKE_OPTS) install );
endef

define Package/accel-pptp/install
	$(INSTALL_DIR) $(1)/usr/lib/pppd/$(PKG_PPP_VERSION)
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/lib/pptp.so.0.0.0 $(1)/usr/lib/pppd/$(PKG_PPP_VERSION)/pptp.so
	$(INSTALL_DIR) $(1)/etc/ppp
	$(INSTALL_DATA) ./files/options.pptp $(1)/etc/ppp/
	$(INSTALL_DIR) $(1)/lib/network
	$(INSTALL_BIN) ./files/pptp.sh $(1)/lib/network/
	$(INSTALL_DIR) $(1)/sbin
	$(INSTALL_BIN) ./files/set_pptp_options $(1)/sbin
endef

$(eval $(call BuildPackage,accel-pptp))
