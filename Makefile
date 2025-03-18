TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WherePlay

WherePlay_FILES = Tweak.x
WherePlay_CFLAGS = -fobjc-arc

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	WherePlay_CFLAGS = -fobjc-arc -DIS_ROOTLESS=1
endif

include $(THEOS_MAKE_PATH)/tweak.mk
