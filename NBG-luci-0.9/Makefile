include build/config.mk

MODULES = contrib/* applications/* libs/* modules/* themes/* i18n/*

OS:=$(shell uname)
export OS

STREAMBOOST_ENABLED:=$(shell grep "CONFIG_PACKAGE_zyxel-streamboost=" $(TOPDIR)/.config |grep y |cut -d '=' -f 2 )

.PHONY: all build gccbuild luabuild clean host gcchost luahost hostcopy hostclean

all: build

build: gccbuild luabuild

gccbuild:
	make -C libs/lmo CC="cc" CFLAGS="" LDFLAGS="" host-install
	for i in $(MODULES); do \
		make -C$$i compile || { \
			echo "*** Compilation of $$i failed!"; \
			exit 1; \
		}; \
	done

luabuild: i18nbuild
	for i in $(MODULES); do HOST=$(realpath host) make -C$$i luabuild; done

i18nbuild: po
	mkdir -p host/lua-po
	./build/i18n-po2lua.pl $(realpath host)/po host/lua-po

clean:
	rm -rf docs
	make -C libs/lmo host-clean
	for i in $(MODULES); do make -C$$i clean; done


host: build hostcopy

gcchost: gccbuild hostcopy

luahost: luabuild hostcopy

hostcopy: 
	mkdir -p host/tmp
	for i in $(MODULES); do cp -pR $$i/dist/* host/ 2>/dev/null || true; done
	for i in $(MODULES); do cp -pR $$i/hostfiles/* host/ 2>/dev/null || true; done
	rm -f host/luci
	ln -s .$(LUCI_MODULEDIR) host/luci
	rm -rf /tmp/luci-* || true

hostenv: host ucidefaults

ucidefaults:
	build/hostenv.sh $(realpath host) $(LUA_MODULEDIR) $(LUA_LIBRARYDIR) "$(realpath host)/bin/uci-defaults --exclude luci-freifunk-*"

runhttpd: hostenv
	build/hostenv.sh $(realpath host) $(LUA_MODULEDIR) $(LUA_LIBRARYDIR) "lua build/lucid.lua"

runlua: hostenv
	build/hostenv.sh $(realpath host) $(LUA_MODULEDIR) $(LUA_LIBRARYDIR) "lua -i build/setup.lua"

runshell: hostenv
	build/hostenv.sh $(realpath host) $(LUA_MODULEDIR) $(LUA_LIBRARYDIR) $$SHELL

hostclean: clean
	rm -rf host

apidocs: hostenv
	build/hostenv.sh $(realpath host) $(LUA_MODULEDIR) $(LUA_LIBRARYDIR) "build/makedocs.sh host/luci/ docs"

uvldocs: hostenv
	build/hostenv.sh $(realpath host) $(LUA_MODULEDIR) $(LUA_LIBRARYDIR) \
	"build/uvldoc $(realpath host) $(UVL_SCHEMEDIR) uvldocs $(DOCS)"

po: host
ifeq ($(STREAMBOOST_ENABLED),y)
	cp -rf $(TOPDIR)/package/zyxel-streamboost/i18n .
endif
	for L in $${LANGUAGE:-$$(find i18n/ -path 'i18n/*/luasrc/i18n/*' -name '*.*.lua' | \
	  sed -e 's!.*/*\.\(.*\)\.lua!\1!')}; do \
	    build/i18n-lua2po.pl . $(realpath host)/po $$L; \
	done

run:
	#	make run is deprecated				#
	#	Please use:					#
	#							#
	#	To run LuCI WebUI using LuCIttpd		#
	#	make runhttpd					#
	#							#
	#	To run LuCI WebUI using Boa/Webuci		#
	#	make runboa 					#
	#							#
	#	To start a shell in the LuCI environment	#
	#	make runshell					#
	#							#
	#	To run Lua CLI in the LuCI environment		#
	#	make runlua					#
