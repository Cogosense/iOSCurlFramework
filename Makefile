#
# supports architectures armv7, armv7s, arm64, i386, x86_64 and bitcode
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
# Xcode bitcode support:
# make ARCHS="armv7 arm64" ENABLE_BITCODE=YES BITCODE_GENERATION_MODE=bitcode - create bitcode
# make ARCHS="armv7 arm64" ENABLE_BITCODE=YES BITCODE_GENERATION_MODE=marker - add bitcode marker (but no real bitcode)
#
# The ENABLE_BITCODE and BITCODE_GENERATION_MODE flags are set in the Xcode project settings
#

SHELL = /bin/bash

#
# set or unset warning flags
#
WFLAGS = -Wno-tautological-pointer-compare -Wno-deprecated-declarations

#
# set minimum iOS version supported
#
ifneq "$(IPHONEOS_DEPLOYMENT_TARGET)" ""
    MIN_IOS_VER = $(IPHONEOS_DEPLOYMENT_TARGET)
else
    MIN_IOS_VER = 8.0
endif

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
VERSION = 7.61.1
TOPDIR = $(CURDIR)
#
# ARCHS, BUILT_PRODUCTS_DIR and DERIVED_FILE_DIR are set by xcode
# only set them if make is invoked directly
#
ARCHS ?= $(ARM_V7_ARCH) $(ARM_V7S_ARCH) $(ARM_64_ARCH) $(I386_ARCH) $(X86_64_ARCH)
BUILT_PRODUCTS_DIR ?= $(TOPDIR)/build
OBJECT_FILE_DIR ?= $(TOPDIR)/build
DERIVED_SOURCES_DIR ?= $(TOPDIR)/build
PROJECT_TEMP_DIR ?= $(TOPDIR)/build
SRCROOT = $(DERIVED_SOURCES_DIR)
BUILDROOT = $(OBJECT_FILE_DIR)
SRCDIR = $(SRCROOT)/$(NAME)-$(VERSION)
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

#
# Files used to trigger builds for each architecture
# TARGET_BUILD_LIB file under install prefix that can be built directly
# TARGET_NOBUILD_ARTIFACT file under install prefix that is built indirectly
#
TARGET_BUILD_LIB = /lib/libcurl.a
TARGET_NOBUILD_ARTIFACT = /bin/curl

INSTALLED_BUILD_LIB = $(FRAMEWORKBUNDLE)$(TARGET_BUILD_LIB)
INSTALLED_NOBUILD_ARTIFACT = $(FRAMEWORKBUNDLE)$(TARGET_NOBUILD_ARTIFACT)

BUILT_LIBS = $(addprefix $(BUILDROOT)/, $(addsuffix /$(INSTALLED_BUILD_LIB), $(ARCHS)))
NOBUILD_ARTIFACTS = $(addprefix $(BUILDROOT)/, $(addsuffix /$(INSTALLED_NOBUILD_ARTIFACT), $(ARCHS)))

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

all install : framework-build

distclean : clean
	$(RM) $(PROJECT_TEMP_DIR)/$(TARBALL)

clean : mostlyclean
	$(RM) -r $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)
	$(RM) -r $(SRCDIR)
	$(RM) $(FRAMEWORKBUNDLE).tar.bz2
	$(RM) -r DerivedData

mostlyclean :
	$(RM) Info.plist
	$(RM) -r $(BUILDROOT)/$(ARM_V7_ARCH)
	$(RM) -r $(BUILDROOT)/$(ARM_V7S_ARCH)
	$(RM) -r $(BUILDROOT)/$(ARM_64_ARCH)
	$(RM) -r $(BUILDROOT)/$(I386_ARCH)
	$(RM) -r $(BUILDROOT)/$(X86_64_ARCH)

env :
	env

$(PROJECT_TEMP_DIR)/$(TARBALL) :
	mkdir -p $(PROJECT_TEMP_DIR)
	curl -L --retry 10 -s -o $@ $(DOWNLOAD_URL) || { \
	    $(RM) $@ ; \
	    exit 1 ; \
	}

$(SRCDIR)/configure : $(PROJECT_TEMP_DIR)/$(TARBALL)
	mkdir -p $(SRCROOT)
	tar -C $(SRCROOT) -xmf $(PROJECT_TEMP_DIR)/$(TARBALL)
	if [ -d patches/$(VERSION) ] ; then \
		for p in patches/$(VERSION)/*.patch ; do \
			if [ -f $$p ] ; then \
				patch -d $(SRCDIR) -p1 < $$p ; \
			fi ; \
		done ; \
	fi


$(BUILDROOT)/$(ARM_V7_ARCH) \
$(BUILDROOT)/$(ARM_V7S_ARCH) \
$(BUILDROOT)/$(ARM_64_ARCH) \
$(BUILDROOT)/$(I386_ARCH) \
$(BUILDROOT)/$(X86_64_ARCH) :
	mkdir -p $@

$(BUILDROOT)/$(ARM_V7_ARCH)/$(INSTALLED_BUILD_LIB) : AC_HOST = $(ARM_V7_HOST)
$(BUILDROOT)/$(ARM_V7_ARCH)/$(INSTALLED_BUILD_LIB) : AC_SDK = iphoneos
$(BUILDROOT)/$(ARM_V7_ARCH)/$(INSTALLED_BUILD_LIB) : AC_C_ARCH = -arch $(ARM_V7_ARCH)
$(BUILDROOT)/$(ARM_V7_ARCH)/$(INSTALLED_BUILD_LIB) : AC_CPP_ARCH = -arch arm
$(BUILDROOT)/$(ARM_V7_ARCH)/$(INSTALLED_BUILD_LIB) : $(BUILDROOT)/$(ARM_V7_ARCH) $(BUILDROOT)/$(ARM_V7_ARCH)/Makefile
	$(MAKE) -C $(BUILDROOT)/$(ARM_V7_ARCH) DESTDIR=$(BUILDROOT)/$(ARM_V7_ARCH) LIBTOOLFLAGS=-Wnone install

$(BUILDROOT)/$(ARM_V7S_ARCH)/$(INSTALLED_BUILD_LIB) : AC_HOST = $(ARM_V7S_HOST)
$(BUILDROOT)/$(ARM_V7S_ARCH)/$(INSTALLED_BUILD_LIB) : AC_SDK = iphoneos
$(BUILDROOT)/$(ARM_V7S_ARCH)/$(INSTALLED_BUILD_LIB) : AC_C_ARCH = -arch $(ARM_V7S_ARCH)
$(BUILDROOT)/$(ARM_V7S_ARCH)/$(INSTALLED_BUILD_LIB) : AC_CPP_ARCH = -arch arm
$(BUILDROOT)/$(ARM_V7S_ARCH)/$(INSTALLED_BUILD_LIB) : $(BUILDROOT)/$(ARM_V7S_ARCH) $(BUILDROOT)/$(ARM_V7S_ARCH)/Makefile
	$(MAKE) -C $(BUILDROOT)/$(ARM_V7S_ARCH) DESTDIR=$(BUILDROOT)/$(ARM_V7S_ARCH) LIBTOOLFLAGS=-Wnone install

$(BUILDROOT)/$(ARM_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_HOST = $(ARM_64_HOST)
$(BUILDROOT)/$(ARM_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_SDK = iphoneos
$(BUILDROOT)/$(ARM_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_C_ARCH = -arch $(ARM_64_ARCH)
$(BUILDROOT)/$(ARM_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_CPP_ARCH = -arch arm
$(BUILDROOT)/$(ARM_64_ARCH)/$(INSTALLED_BUILD_LIB) : $(BUILDROOT)/$(ARM_64_ARCH) $(BUILDROOT)/$(ARM_64_ARCH)/Makefile
	$(MAKE) -C $(BUILDROOT)/$(ARM_64_ARCH) DESTDIR=$(BUILDROOT)/$(ARM_64_ARCH) LIBTOOLFLAGS=-Wnone install

$(BUILDROOT)/$(I386_ARCH)/$(INSTALLED_BUILD_LIB) : AC_HOST = $(I386_HOST)
$(BUILDROOT)/$(I386_ARCH)/$(INSTALLED_BUILD_LIB) : AC_SDK = iphonesimulator
$(BUILDROOT)/$(I386_ARCH)/$(INSTALLED_BUILD_LIB) : AC_C_ARCH = -arch $(I386_ARCH)
$(BUILDROOT)/$(I386_ARCH)/$(INSTALLED_BUILD_LIB) : AC_CPP_ARCH = -arch $(I386_ARCH)
$(BUILDROOT)/$(I386_ARCH)/$(INSTALLED_BUILD_LIB) : $(BUILDROOT)/$(I386_ARCH) $(BUILDROOT)/$(I386_ARCH)/Makefile
	$(MAKE) -C $(BUILDROOT)/$(I386_ARCH) DESTDIR=$(BUILDROOT)/$(I386_ARCH) LIBTOOLFLAGS=-Wnone install

$(BUILDROOT)/$(X86_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_HOST = $(X86_64_HOST)
$(BUILDROOT)/$(X86_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_SDK = iphonesimulator
$(BUILDROOT)/$(X86_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_C_ARCH = -arch $(X86_64_ARCH)
$(BUILDROOT)/$(X86_64_ARCH)/$(INSTALLED_BUILD_LIB) : AC_CPP_ARCH = -arch $(I386_ARCH)
$(BUILDROOT)/$(X86_64_ARCH)/$(INSTALLED_BUILD_LIB) : $(BUILDROOT)/$(X86_64_ARCH) $(BUILDROOT)/$(X86_64_ARCH)/Makefile
	 $(MAKE) -C $(BUILDROOT)/$(X86_64_ARCH) DESTDIR=$(BUILDROOT)/$(X86_64_ARCH) LIBTOOLFLAGS=-Wnone install

#
# Because of the way curl enbeds the architecture into the code
# using generated header files, the 32bit and 64bit code must be
# built seperately and then combined later using lipo
#
$(BUILDROOT)/$(ARM_V7_ARCH)/Makefile \
$(BUILDROOT)/$(ARM_V7S_ARCH)/Makefile \
$(BUILDROOT)/$(ARM_64_ARCH)/Makefile \
$(BUILDROOT)/$(I386_ARCH)/Makefile \
$(BUILDROOT)/$(X86_64_ARCH)/Makefile : $(SRCDIR)/configure
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
		CFLAGS='-miphoneos-version-min=$(MIN_IOS_VER) $(XCODE_BITCODE_FLAG) $(WFLAGS)' \
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

.PHONY : framework-archs-cmp
framework-archs-cmp :
	@found='no' ; \
	if [ -f "$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME)" ] ; then \
		archs=`lipo -info "$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME)" | awk -F: '{print $$3}'` ; \
		for archReq in $(ARCHS) ; do \
			for archHave in $$archs ; do \
				if [ $$archReq == $$archHave ] ; then \
					found='yes' ; \
					break ; \
				fi ; \
			done ; \
			if [ $$found == 'no' ] ; then \
				break ; \
			fi ; \
		done ; \
	fi ; \
	if [ $$found == 'no' ] ; then \
		$(RM) $(FRAMEWORKBUNDLE).tar.bz2 ; \
		echo "rebuilding $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE) for $(ARCHS)" ; \
	fi

framework-build: FRAMEWORKBUNDLE_DEPS = $(BUILT_LIBS)
framework-build: framework-archs-cmp $(BUILT_LIBS) $(FRAMEWORKBUNDLE).tar.bz2

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
framework-no-build: FRAMEWORKBUNDLE_DEPS = $(NOBUILD_ARTIFACTS)
framework-no-build: framework-archs-cmp $(NOBUILD_ARTIFACTS) $(FRAMEWORKBUNDLE).tar.bz2

$(FRAMEWORKBUNDLE).tar.bz2 : $(FRAMEWORKBUNDLE_DEPS)
	$(MAKE) bundle
	$(RM) $(FRAMEWORKBUNDLE).tar.bz2
	tar -C $(BUILT_PRODUCTS_DIR) -cjf $(FRAMEWORKBUNDLE).tar.bz2 $(FRAMEWORKBUNDLE)

FIRST_ARCH = $(firstword $(ARCHS))

.PHONY : bundle-dirs bundle-resources bundle-headers bundle-libraries system-framework-dirs

bundle : bundle-dirs bundle-resources bundle-headers bundle-libraries system-framework-dirs

#
# This directory should be added to SYSTEM_FRAMEWORK_SEARCH_PATHS in dependent
# projects to suppress the generation of warnings from the framework.
#
# This framework can also be found using FRAMEWORK_SEARCH_PATHS, so ensure the
# SYSTEM version is in the compiler command line before the USER version
#
system-framework-dirs :
	mkdir -p $(BUILT_PRODUCTS_DIR)/System
	ln -sf ../$(FRAMEWORKBUNDLE)  $(BUILT_PRODUCTS_DIR)/System/$(FRAMEWORKBUNDLE)

bundle-dirs :
	mkdir -p $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)
	mkdir -p $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions
	mkdir -p $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)
	mkdir -p $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Resources
	mkdir -p $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers
	mkdir -p $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Documentation
	ln -sf $(FRAMEWORK_VERSION) $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/Current
	ln -sf Versions/Current/Headers $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Headers
	ln -sf Versions/Current/Resources $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Resources
	ln -sf Versions/Current/Documentation $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Documentation
	ln -sf Versions/Current/$(FRAMEWORK_NAME) $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME)

bundle-resources : Info.plist bundle-dirs
	cp Info.plist $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Resources/

bundle-headers : bundle-dirs
	cp -a $(BUILDROOT)/$(FIRST_ARCH)/$(FRAMEWORKBUNDLE)/include/curl/ $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/Headers/

bundle-libraries : bundle-dirs
	xcrun -sdk iphoneos lipo -create $(BUILT_LIBS) -o $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Versions/$(FRAMEWORK_VERSION)/$(FRAMEWORK_NAME)
