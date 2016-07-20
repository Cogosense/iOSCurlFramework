#
# supports architectures armv7, armv7s, arm64, i386 and x86_64
#
# make - build a fat archive framework using $ARCHS, if $ARCHS is empty all architectures are built (device and simulator)
# make ARCHS=i386   \
# make ARCHS=x86_64  |
# make ARCHS=armv7    > build a thin archive framework with named architecture
# make ARCHS=armv7s  |
# make ARCHS=arm64  /
# make ARCHS='i386 x86_64' - bulid a fat archive framework with only the named architectures
#
# From xcode build script:
# make ARCHS=${ARCHS} - build all active architectures
#
SHELL = /bin/bash

#
# set minimum iOS version supported
#
MIN_IOS_VER = 6.1

#
# enable bitcode support
#
ifeq "$(ENABLE_BITCODE)" "YES"
    ifeq "$(BITCODE_GENERATION_MODE)" "marker"
	XCODE_BITCODE_FLAG = -fembed-bitcode-marker
    endif
    ifeq "$(BITCODE_GENERATION_MODE)" "bitcode"
	XCODE_BITCODE_FLAG = -fembed-bitcode
    endif
endif

empty:=
space:= $(empty) $(empty)
comma:= ,

NAME = curl
VERSION = 7.42.1
TOPDIR = $(CURDIR)
SRCDIR = $(TOPDIR)/$(NAME)-$(VERSION)
#
# ARCHS, BUILD_DIR and DERIVED_FILE_DIR are set by xcode
# only set them if make is invoked directly
#
ARCHS ?= $(ARM_V7_ARCH) $(ARM_V7S_ARCH) $(ARM_64_ARCH) $(I386_ARCH) $(X86_64_ARCH)
BUILD_DIR ?= $(TOPDIR)/build
DERIVED_FILE_DIR ?= $(TOPDIR)/build
TARBALL = $(NAME)-$(VERSION).tar.gz
ARM_V7_HOST = armv7-apple-darwin
ARM_V7S_HOST = armv7s-apple-darwin
ARM_64_HOST = aarch64-apple-darwin
I386_HOST = i386-apple-darwin
X86_64_HOST = x86_64-apple-darwin
ARM_V7_ARCH = armv7
ARM_V7S_ARCH = armv7s
ARM_64_ARCH = arm64
I386_ARCH = i386
X86_64_ARCH = x86_64
FRAMEWORK_VERSION = A
FRAMEWORK_NAME = curl
FRAMEWORKBUNDLE = $(FRAMEWORK_NAME).framework
DOWNLOAD_URL = http://curl.haxx.se/download/$(TARBALL)

define Info_plist
<?xml version="1.0" encoding="UTF-8"?>\n
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n
<plist version="1.0">\n
<dict>\n
\t<key>CFBundleDevelopmentRegion</key>\n
\t<string>English</string>\n
\t<key>CFBundleExecutable</key>\n
\t<string>$(FRAMEWORK_NAME)</string>\n
\t<key>CFBundleIdentifier</key>\n
\t<string>se.haxx.curl</string>\n
\t<key>CFBundleInfoDictionaryVersion</key>\n
\t<string>$(VERSION)</string>\n
\t<key>CFBundlePackageType</key>\n
\t<string>FMWK</string>\n
\t<key>CFBundleSignature</key>\n
\t<string>????</string>\n
\t<key>CFBundleVersion</key>\n
\t<string>$(VERSION)</string>\n
</dict>\n
</plist>\n
endef

define curlbuild_h
//\n
// Generated wrapper to support mach fat archives\n
// with multiple architectures.\n
//\n
// libcurl generates an architecture specific header\n
// file during the build process. These must be combined\n
// into the framework and the correct one selected at\n
// compile time.\n
//\n
#ifndef CURLBUILD_WRAPPER_H\n
#define CURLBUILD_WRAPPER_H\n
#ifdef __arm64__\n
#include "curlbuild_$(ARM_64_ARCH).h"\n
#endif\n
#ifdef __armv7__\n
#include "curlbuild_$(ARM_V7_ARCH).h"\n
#endif\n
#ifdef __armv7s__\n
#include "curlbuild_$(ARM_V7S_ARCH).h"\n
#endif\n
#ifdef __x86_64__\n
#include "curlbuild_$(X86_64_ARCH).h"\n
#endif\n
#ifdef __i386__\n
#include "curlbuild_$(I386_ARCH).h"\n
#endif\n
#endif\n
endef

all : env framework-build

distclean : clean
	$(RM) $(TARBALL)

clean : mostlyclean
	$(RM) -r $(BUILD_DIR)/$(FRAMEWORKBUNDLE)
	$(RM) -r $(SRCDIR)
	$(RM) $(FRAMEWORKBUNDLE).tar.bz2

mostlyclean :
	$(RM) Info.plist
	$(RM) -r $(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)
	$(RM) -r $(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)
	$(RM) -r $(DERIVED_FILE_DIR)/$(ARM_64_ARCH)
	$(RM) -r $(DERIVED_FILE_DIR)/$(I386_ARCH)
	$(RM) -r $(DERIVED_FILE_DIR)/$(X86_64_ARCH)

env :
	env

$(TARBALL) :
	curl -L --retry 10 -s -o $@ $(DOWNLOAD_URL) || $(RM) $@

$(SRCDIR)/configure : $(TARBALL)
	tar xf $(TARBALL)

$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH) \
$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH) \
$(DERIVED_FILE_DIR)/$(ARM_64_ARCH) \
$(DERIVED_FILE_DIR)/$(I386_ARCH) \
$(DERIVED_FILE_DIR)/$(X86_64_ARCH) :
	mkdir -p $@

$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/$(FRAMEWORKBUNDLE) : AC_HOST = $(ARM_V7_HOST)
$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/$(FRAMEWORKBUNDLE) : AC_SDK = iphoneos
$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/$(FRAMEWORKBUNDLE) : AC_C_ARCH = -arch $(ARM_V7_ARCH)
$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/$(FRAMEWORKBUNDLE) : AC_CPP_ARCH = -arch arm
$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/$(FRAMEWORKBUNDLE) : $(DERIVED_FILE_DIR)/$(ARM_V7_ARCH) $(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/Makefile
	$(MAKE) -C $(DERIVED_FILE_DIR)/$(ARM_V7_ARCH) DESTDIR=$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH) install

$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/$(FRAMEWORKBUNDLE) : AC_HOST = $(ARM_V7S_HOST)
$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/$(FRAMEWORKBUNDLE) : AC_SDK = iphoneos
$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/$(FRAMEWORKBUNDLE) : AC_C_ARCH = -arch $(ARM_V7S_ARCH)
$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/$(FRAMEWORKBUNDLE) : AC_CPP_ARCH = -arch arm
$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/$(FRAMEWORKBUNDLE) : $(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH) $(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/Makefile
	$(MAKE) -C $(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH) DESTDIR=$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH) install

$(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_HOST = $(ARM_64_HOST)
$(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_SDK = iphoneos
$(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_C_ARCH = -arch $(ARM_64_ARCH)
$(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_CPP_ARCH = -arch arm
$(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/$(FRAMEWORKBUNDLE) : $(DERIVED_FILE_DIR)/$(ARM_64_ARCH) $(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/Makefile
	$(MAKE) -C $(DERIVED_FILE_DIR)/$(ARM_64_ARCH) DESTDIR=$(DERIVED_FILE_DIR)/$(ARM_64_ARCH) install

$(DERIVED_FILE_DIR)/$(I386_ARCH)/$(FRAMEWORKBUNDLE) : AC_HOST = $(I386_HOST)
$(DERIVED_FILE_DIR)/$(I386_ARCH)/$(FRAMEWORKBUNDLE) : AC_SDK = iphonesimulator
$(DERIVED_FILE_DIR)/$(I386_ARCH)/$(FRAMEWORKBUNDLE) : AC_C_ARCH = -arch $(I386_ARCH)
$(DERIVED_FILE_DIR)/$(I386_ARCH)/$(FRAMEWORKBUNDLE) : AC_CPP_ARCH = -arch $(I386_ARCH)
$(DERIVED_FILE_DIR)/$(I386_ARCH)/$(FRAMEWORKBUNDLE) : $(DERIVED_FILE_DIR)/$(I386_ARCH) $(DERIVED_FILE_DIR)/$(I386_ARCH)/Makefile
	$(MAKE) -C $(DERIVED_FILE_DIR)/$(I386_ARCH) DESTDIR=$(DERIVED_FILE_DIR)/$(I386_ARCH) install

$(DERIVED_FILE_DIR)/$(X86_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_HOST = $(X86_64_HOST)
$(DERIVED_FILE_DIR)/$(X86_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_SDK = iphonesimulator
$(DERIVED_FILE_DIR)/$(X86_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_C_ARCH = -arch $(X86_64_ARCH)
$(DERIVED_FILE_DIR)/$(X86_64_ARCH)/$(FRAMEWORKBUNDLE) : AC_CPP_ARCH = -arch $(I386_ARCH)
$(DERIVED_FILE_DIR)/$(X86_64_ARCH)/$(FRAMEWORKBUNDLE) : $(DERIVED_FILE_DIR)/$(X86_64_ARCH) $(DERIVED_FILE_DIR)/$(X86_64_ARCH)/Makefile
	 $(MAKE) -C $(DERIVED_FILE_DIR)/$(X86_64_ARCH) DESTDIR=$(DERIVED_FILE_DIR)/$(X86_64_ARCH) install

#
# Because of the way curl enbeds the architecture into the code
# using generated header files, the 32bit and 64bit code must be
# built seperately and then combined later using lipo
#
$(DERIVED_FILE_DIR)/$(ARM_V7_ARCH)/Makefile \
$(DERIVED_FILE_DIR)/$(ARM_V7S_ARCH)/Makefile \
$(DERIVED_FILE_DIR)/$(ARM_64_ARCH)/Makefile \
$(DERIVED_FILE_DIR)/$(I386_ARCH)/Makefile \
$(DERIVED_FILE_DIR)/$(X86_64_ARCH)/Makefile : $(SRCDIR)/configure
	cd $(dir $@) && \
	    $(SRCDIR)/configure \
		--prefix=/$(FRAMEWORKBUNDLE) \
		--host=$(AC_HOST) \
		--disable-shared \
		--enable-ipv6 \
		--disable-ldap \
		--disable-ldaps \
		--disable-tftp \
		--disable-smb \
		--disable-gopher \
		--disable-manual \
		--without-libssh2 \
		--with-darwinssl \
		-without-libidn \
		CC='xcrun --sdk $(AC_SDK) clang $(AC_C_ARCH)' \
		CFLAGS='-miphoneos-version-min=$(MIN_IOS_VER) $(XCODE_BITCODE_FLAG)' \
		CPP='xcrun --sdk $(AC_SDK) clang $(AC_CPP_ARCH) -E' \
		AR='xcrun --sdk $(AC_SDK) ar' \
		LD='xcrun --sdk $(AC_SDK) ld' \
		LIPO='xcrun --sdk $(AC_SDK) lipo' \
		OTOOL='xcrun --sdk $(AC_SDK) otool' \
		STRIP='xcrun --sdk $(AC_SDK) strip' \
		NM='xcrun --sdk $(AC_SDK) nm' \
		LIBTOOL='xcrun --sdk $(AC_SDK) libtool'

export Info_plist

Info.plist : Makefile
	echo -e $$Info_plist > $@

framework-build: $(addprefix $(DERIVED_FILE_DIR)/, $(addsuffix /$(FRAMEWORKBUNDLE), $(ARCHS))) $(FRAMEWORKBUNDLE).tar.bz2

#
# The framework-no-build target is used by Jenkins to assemble
# the results of the individual architectures built in parallel.
#
# The pipeline stash/unstash feature is used to assemble the build
# results from each parallel phase.
#
# This target depends on a built file in each framework bundle,
# if it is missing then the build fails as the master has no
# rules to build it.
#
framework-no-build: $(addprefix $(DERIVED_FILE_DIR)/, $(addsuffix /$(FRAMEWORKBUNDLE)/bin/$(NAME), $(ARCHS))) $(FRAMEWORKBUNDLE).tar.bz2

export curlbuild_h

FIRST_ARCH = $(firstword $(ARCHS))

bundle-dirs :
	$(RM) -r $(BUILD_DIR)/$(FRAMEWORKBUNDLE)
	mkdir $(BUILD_DIR)/$(FRAMEWORKBUNDLE)
	mkdir $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions
	mkdir $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)
	mkdir $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Resources
	mkdir $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers
	mkdir $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Documentation
	ln -s $(FRAMEWORK_VERSION) $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/Current
	ln -s Versions/Current/Headers $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Headers
	ln -s Versions/Current/Resources $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Resources
	ln -s Versions/Current/Documentation $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Documentation
	ln -s Versions/Current/$(FRAMEWORK_NAME) $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME)

bundle-resources : Info.plist bundle-dirs
	cp Info.plist $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Resources/

bundle-headers : bundle-dirs
	cp -R $(DERIVED_FILE_DIR)/$(FIRST_ARCH)/$(FRAMEWORKBUNDLE)/include/curl/ $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers/
	$(RM) $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild.h
	for arch in $(ARCHS) ; do \
	    cp $(DERIVED_FILE_DIR)/$${arch}/$(FRAMEWORKBUNDLE)/include/curl/curlbuild.h $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild_$${arch}.h ; \
	done
	echo -e $$curlbuild_h > $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild.h

bundle-libraries : bundle-dirs
	for arch in $(ARCHS) ; do libs="$$libs $(DERIVED_FILE_DIR)/$$arch/$(FRAMEWORKBUNDLE)/lib/libcurl.a" ; done ; \
	xcrun -sdk iphoneos lipo -create $$libs -o $(BUILD_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/$(FRAMEWORK_NAME)

$(FRAMEWORKBUNDLE) : bundle-dirs bundle-resources bundle-headers bundle-libraries

$(FRAMEWORKBUNDLE).tar.bz2 : $(FRAMEWORKBUNDLE)
	$(RM) -f $(FRAMEWORKBUNDLE).tar.bz2
	tar -C $(BUILD_DIR) -cjf $(FRAMEWORKBUNDLE).tar.bz2 $(FRAMEWORKBUNDLE)

