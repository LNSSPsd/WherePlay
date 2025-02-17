TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WherePlay

WherePlay_FILES = Tweak.x
WherePlay_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
