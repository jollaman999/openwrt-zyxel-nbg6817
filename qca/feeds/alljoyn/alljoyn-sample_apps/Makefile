# Copyright (c) 2013 - 2014, AllSeen Alliance. All rights reserved.
#
#    Permission to use, copy, modify, and/or distribute this software for any
#    purpose with or without fee is hereby granted, provided that the above
#    copyright notice and this permission notice appear in all copies.
#
#    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

AJ_SERVICE:=sample_apps
AJ_SERVICE_NAME:=sample_apps
JSON_LIB:=json

include $(TOPDIR)/rules.mk

PKG_NAME:=alljoyn-$(AJ_SERVICE)
PKG_VERSION:=14.02.00
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)-src
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-src.tar.gz
#PKG_SOURCE_URL:=https://allseenalliance.org/sites/default/files/resources/
PKG_SOURCE_URL:=@ZyXEL_SITE/opensource/network/utils
PKG_MD5SUM:=afa3d5483682100eb108617e21f91ae2

# SCons supports parallel builds but does not support make's jobserver
PKG_BUILD_PARALLEL:=$(if $(CONFIG_PKG_BUILD_USE_JOBSERVER),0,1)

PKG_CONFIG_DEPENDS:= CONFIG_PACKAGE_$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

ALLJOYN_BINDINGS:=cpp,
ALLJOYN_BUILD_SERVICES_SAMPLES:=on

define Package/$(PKG_NAME)
  TITLE:=AllJoyn services $(AJ_SERVICE_NAME) - sample applications
  SECTION:=net
  CATEGORY:=Network
  DEPENDS:=alljoyn \
	+alljoyn-about \
	+alljoyn-config \
	+alljoyn-controlpanel \
	+alljoyn-notification \
	+alljoyn-onboarding \
	+alljoyn-services_common \
	+lib$(JSON_LIB) \
	+luci-lib-json
  URL:=http://www.allseenalliance.org
  MAINTAINER:=AllSeen Alliance <allseen-core@lists.allseenalliance.org>
endef

define Package/$(PKG_NAME)/description
AllJoyn services $(AJ_SERVICE_NAME) sample applications - includes ServerSample and ACServerSample.
endef

ifeq ($(CONFIG_DEBUG),y)
  ALLJOYN_BUILD_VARIANT:=debug
else
  ALLJOYN_BUILD_VARIANT:=release
endif


PKG_INSTALL_DIR:=$(PKG_BUILD_DIR)/services/$(AJ_SERVICE)/build/openwrt/openwrt/$(ALLJOYN_BUILD_VARIANT)/dist/$(AJ_SERVICE)

TARGET_CFLAGS+=-fPIC
TARGET_CPPFLAGS+=-fPIC

define Build/Configure/Default
# Override default to do nothing
endef

define Build/Compile
	scons -C $(PKG_BUILD_DIR)/services/$(AJ_SERVICE) \
		$(PKG_JOBS) \
		WS=off \
		CPU=openwrt \
		OS=openwrt \
		"BINDINGS=$(ALLJOYN_BINDINGS)" \
		"BUILD_SERVICES_SAMPLES=$(ALLJOYN_BUILD_SERVICES_SAMPLES)" \
		"JSON_LIB=$(JSON_LIB)" \
		"VARIANT=$(ALLJOYN_BUILD_VARIANT)" \
		BD=off \
		BT=off \
		ICE=off \
		"TARGET_CC=$$(TARGET_CC)" \
		"TARGET_CXX=$$(TARGET_CXX)" \
		"TARGET_CFLAGS=$$(TARGET_CFLAGS)" \
		"TARGET_CPPFLAGS=$$(TARGET_CPPFLAGS)" \
		"TARGET_PATH=$$(TARGET_PATH)" \
		"TARGET_LINKFLAGS=$$(TARGET_LDFLAGS)" \
		"TARGET_LINK=$$(TARGET_CC)" \
		"TARGET_AR=$$(TARGET_AR)" \
		"TARGET_RANLIB=$$(TARGET_RANLIB)" \
		"STAGING_DIR=$$(STAGING_DIR)" \
		"ALL=1"
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/* $(1)/usr/bin/
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/* $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/alljoyn-onboarding.init $(1)/etc/init.d/alljoyn-onboarding
	$(INSTALL_BIN) ./files/alljoyn-onboarding-reload.init $(1)/etc/init.d/alljoyn-onboarding-reload
	$(INSTALL_BIN) ./files/wifi_scan.init $(1)/etc/init.d/wifi_scan
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/alljoyn-onboarding.defaults $(1)/etc/uci-defaults/alljoyn-onboarding
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/alljoyn-onboarding.config $(1)/etc/config/alljoyn-onboarding
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/wifi_scan $(1)/usr/sbin/wifi_scan
	$(INSTALL_BIN) ./files/wifi_mgmt $(1)/usr/sbin/wifi_mgmt
	$(INSTALL_DIR) $(1)/etc/alljoyn-onboarding
	$(CP) $(PKG_BUILD_DIR)/services/sample_apps/cpp/samples/ACServerSample/ACServerSample.conf $(1)/etc/alljoyn-onboarding/
	$(CP) $(PKG_BUILD_DIR)/services/sample_apps/cpp/samples/ServerSample/ServerSample.conf $(1)/etc/alljoyn-onboarding/
	$(CP) $(PKG_BUILD_DIR)/services/sample_apps/cpp/samples/ACServerSample/FactoryACServerSample.conf $(1)/etc/alljoyn-onboarding/
	$(CP) $(PKG_BUILD_DIR)/services/sample_apps/cpp/samples/ServerSample/FactoryServerSample.conf $(1)/etc/alljoyn-onboarding/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    . /etc/uci-defaults/alljoyn-onboarding
    rm -f /etc/uci-defaults/alljoyn-onboarding
fi
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
    /etc/init.d/alljoyn-onboarding stop
    /etc/init.d/alljoyn-onboarding disable
    /etc/init.d/wifi_scan disable
    /etc/init.d/alljoyn-onboarding-reload disable
    uci batch <<EOF
del_list ucitrack.@alljoyn[-1].affects=alljoyn-onboarding
delete ucitrack.@alljoyn-onboarding[-1]
commit ucitrack
EOF
fi
exit 0
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

