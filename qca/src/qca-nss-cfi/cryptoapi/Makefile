# Cryptoapi specifc NSS cfi Makefile

NSS_CRYPTOAPI_MOD_NAME=qca-nss-cfi-cryptoapi

obj-m += $(NSS_CRYPTOAPI_MOD_NAME).o
$(NSS_CRYPTOAPI_MOD_NAME)-objs = nss_cryptoapi.o

obj ?= .

ccflags-y += -I$(obj)/../include
ccflags-y += -I$(obj)/
