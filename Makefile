TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RestoreBackup

RestoreBackup_FILES = Tweak.xm $(wildcard SSZipArchive/*.m) $(wildcard SSZipArchive/minizip/*.c) $(wildcard JGProgressHUD/*.m)
RestoreBackup_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-unused-value -Wno-deprecated-declarations -Wno-nullability-completeness -Wno-unused-function -Wno-incompatible-pointer-types
RestoreBackup_CFLAGS += -DCOCOAPODS=1 -DHAVE_INTTYPES_H -DHAVE_PKCRYPT -DHAVE_STDINT_H -DHAVE_WZAES -DHAVE_ZLIB -DZLIB_COMPAT
RestoreBackup_CFLAGS += -Werror=unused-const-variable
RestoreBackup_CCFLAGS = -DCOCOAPODS=1 -DHAVE_INTTYPES_H -DHAVE_PKCRYPT -DHAVE_STDINT_H -DHAVE_WZAES -DHAVE_ZLIB -DZLIB_COMPAT
#RestoreBackup_CCFLAGS += --Werror=unused-const-variable
RestoreBackup_FRAMEWORKS = Security UIKit Foundation CoreGraphics QuartzCore
RestoreBackup_LIBRARIES = z iconv
RestoreBackup_PRIVATE_FRAMEWORKS = CryptoTokenKit
RestoreBackup_INCLUDE_DIRS = SSZipArchive SSZipArchive/minizip $(THEOS)/vendor/include JGProgressHUD
$(TWEAK_NAME)_LOGOS_DEFAULT_GENERATOR = internal

include $(THEOS_MAKE_PATH)/tweak.mk