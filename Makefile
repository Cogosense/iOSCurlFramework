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
# library to be built
NAME = curl
VERSION = 7.65.1

#
# Download location URL
#
TARBALL = $(NAME)-$(VERSION).tar.gz
DOWNLOAD_URL = http://curl.haxx.se/download/$(TARBALL)

#
# Files used to trigger builds for each architecture
# TARGET_BUILD_LIB file under install prefix that can be built directly
# TARGET_NOBUILD_ARTIFACT file under install prefix that is built indirectly
#
INSTALLED_LIB = /lib/libcurl.a
INSTALLED_HEADER_DIR = /include/curl

#
# Output framework name
#
FRAMEWORK_NAME = $(NAME)

#
# The GNU host triplets corresponding to
# the Xcode build architectures
#
ARM_V7_HOST = armv7-apple-darwin
ARM_V7S_HOST = armv7s-apple-darwin
ARM_64_HOST = aarch64-apple-darwin
I386_HOST = i386-apple-darwin
X86_64_HOST = x86_64-apple-darwin

#
# The supported Xcode build architectures
#
ARM_V7_ARCH = armv7
ARM_V7S_ARCH = armv7s
ARM_64_ARCH = arm64
I386_ARCH = i386
X86_64_ARCH = x86_64

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

#
# ARCHS and BUILT_PRODUCTS_DIR are set by xcode
# only set them if make is invoked directly
#
ARCHS ?= $(ARM_V7_ARCH) $(ARM_V7S_ARCH) $(ARM_64_ARCH) $(I386_ARCH) $(X86_64_ARCH)
BUILT_PRODUCTS_DIR ?= $(CURDIR)/build

MAKER_DIR = $(BUILT_PRODUCTS_DIR)/Maker
MAKER_ARCHIVES_DIR = $(MAKER_DIR)/Archives
MAKER_SOURCES_DIR = $(MAKER_DIR)/Sources
MAKER_BUILD_DIR = $(MAKER_DIR)/Build
MAKER_BUILDROOT_DIR = $(MAKER_DIR)/Buildroot

PKGSRCDIR = $(MAKER_SOURCES_DIR)/$(NAME)-$(VERSION)

FRAMEWORKBUNDLE = $(FRAMEWORK_NAME).framework

.PHONY : \
	all \
	build \
	install \
	clean \
	build-commence \
	build-complete \
	install-commence i\
	nstall-complete \
	dirs \
	tarball \
	configure \
	makefiles \
	$(addprefix Makefile_, $(ARCHS)) \
	builds \
	$(addprefix Build_, $(ARCHS))

all : build

build : build-commence dirs tarball configure makefiles builds bundle build-complete

install : install-commence dirs tarball configure makefiles builds bundle install-complete

clean :
	$(RM) -r $(BUILT_PRODUCTS_DIR)
	$(RM) -r DerivedData
	$(RM) -r Carthage
	$(RM) *.framework.tar.bz2
	$(RM $(FRAMEWORK_NAME).zip
	$(RM) Info.plist

build-commence :
	@echo "Commencing debug build for framework: $(FRAMEWORK_NAME)"

build-complete :
	@echo "Completed debug build for framework: $(FRAMEWORK_NAME)"

install-commence :
	@echo "Commencing release build for framework: $(FRAMEWORK_NAME)"

install-complete :
	@echo "Completed release build for framework: $(FRAMEWORK_NAME)"

dirs : $(MAKER_ARCHIVES_DIR) $(MAKER_SOURCES_DIR) $(MAKER_BUILD_DIR) $(MAKER_BUILDROOT_DIR)

$(MAKER_ARCHIVES_DIR) $(MAKER_SOURCES_DIR) $(MAKER_BUILD_DIR) $(MAKER_BUILDROOT_DIR) :
	mkdir -p $@

tarball : dirs $(MAKER_ARCHIVES_DIR)/$(TARBALL)

$(MAKER_ARCHIVES_DIR)/$(TARBALL) :
	curl -L --retry 10 -s -o $@ $(DOWNLOAD_URL) || { \
	    $(RM) $@ ; \
	    exit 1 ; \
	}

configure : dirs tarball $(PKGSRCDIR)/configure

$(PKGSRCDIR)/configure :
	tar -C $(MAKER_SOURCES_DIR) -xmf $(MAKER_ARCHIVES_DIR)/$(TARBALL)
	if [ -d patches/$(VERSION) ] ; then \
		for p in patches/$(VERSION)/*.patch ; do \
			if [ -f $$p ] ; then \
				patch -d $(PKGSRCDIR) -p1 < $$p ; \
			fi ; \
		done ; \
	fi

makefiles : dirs tarball configure $(addprefix Makefile_, $(ARCHS))

builds : dirs tarball configure makefiles $(addprefix Build_, $(ARCHS))

#
# $1 - GNU host triplet
# $2 - sdk (iphoneos or iphonesimulator)
# $3 - xcode architecture (armv7, armv7s, arm64, i386, x86_64)
# $4 - xcode architecture family (arm, i386)
#
define configure_template

Makefile_$(3) : $(MAKER_BUILD_DIR)/$(1) $(MAKER_BUILD_DIR)/$(1)/Makefile

$(MAKER_BUILD_DIR)/$(1) :
	mkdir -p $$@

$(MAKER_BUILD_DIR)/$(1)/Makefile :
	cd $$(dir $$@) && \
	    $(PKGSRCDIR)/configure \
		--prefix=/$$(FRAMEWORKBUNDLE) \
		--host=$(1) \
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
		CC='xcrun --sdk $(2) clang -arch $(3)' \
		CFLAGS='-miphoneos-version-min=$$(MIN_IOS_VER) $$(XCODE_BITCODE_FLAG) $$(WFLAGS)' \
		CPP='xcrun --sdk $(2) clang -arch $(4) -E' \
		AR='xcrun --sdk $(2) ar' \
		LD='xcrun --sdk $(2) ld' \
		LIPO='xcrun --sdk $(2) lipo' \
		OTOOL='xcrun --sdk $(2) otool' \
		STRIP='xcrun --sdk $(2) strip' \
		NM='xcrun --sdk $(2) nm' \
		LIBTOOL='xcrun --sdk $(2) libtool'

Build_$(3) : $(MAKER_BUILDROOT_DIR)/$(3)/$(FRAMEWORKBUNDLE)$(INSTALLED_LIB)

$(MAKER_BUILDROOT_DIR)/$(3)/$(FRAMEWORKBUNDLE)$(INSTALLED_LIB) :
	$(MAKE) -C $(MAKER_BUILD_DIR)/$(1) DESTDIR=$(MAKER_BUILDROOT_DIR)/$(3) LIBTOOLFLAGS=-Wnone install

endef

$(eval $(call configure_template,$(ARM_V7_HOST),iphoneos,$(ARM_V7_ARCH),arm))
$(eval $(call configure_template,$(ARM_V7S_HOST),iphoneos,$(ARM_V7S_ARCH),arm))
$(eval $(call configure_template,$(ARM_64_HOST),iphoneos,$(ARM_64_ARCH),arm))
$(eval $(call configure_template,$(I386_HOST),iphonesimulator,$(I386_ARCH),$(I386_ARCH)))
$(eval $(call configure_template,$(X86_64_HOST),iphonesimulator,$(X86_64_ARCH),$(I386_ARCH)))

FIRST_ARCH = $(firstword $(ARCHS))

.PHONY : bundle-dirs bundle-headers bundle-rm-fat-library bundle-info

bundle : \
	bundle-dirs \
	bundle-headers \
	bundle-rm-fat-library \
	$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME) \
	bundle-info \
	$(FRAMEWORKBUNDLE).tar.bz2

FRAMEWORK_DIRS = \
	$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE) \
	$(FRAMEWORKBUNDLE)/Resources \
	$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Headers \
	$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Documentation \
	$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Modules

bundle-dirs : $(FRAMEWORK_DIRS)

$(FRAMEWORK_DIRS) :
	mkdir -p $@

bundle-headers : bundle-dirs
	rsync -r -u $(MAKER_BUILDROOT_DIR)/$(FIRST_ARCH)/$(FRAMEWORKBUNDLE)$(INSTALLED_HEADER_DIR)/* $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Headers

$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Info.plist :
	cp $(FRAMEWORK_NAME)/Info.plist $@
	/usr/libexec/plistbuddy -c "Set:CFBundleDevelopmentRegion English" $@
	/usr/libexec/plistbuddy -c "Set:CFBundleExecutable $(NAME)" $@
	/usr/libexec/plistbuddy -c "Set:CFBundleName $(FRAMEWORK_NAME)" $@
	/usr/libexec/plistbuddy -c "Set:CFBundleIdentifier com.cogosense.$(NAME)" $@

bundle-info : $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/Info.plist
	verCode=$$(git tag -l '[0-9]*\.[0-9]*\.[0-9]' | wc -l) ; \
	verStr=$$(git describe --match '[0-9]*\.[0-9]*\.[0-9]' --always) ; \
	/usr/libexec/plistbuddy -c "Set:CFBundleShortVersionString $${verStr}" $< ; \
	/usr/libexec/plistbuddy -c "Set:CFBundleVersion $${verCode}" $<
	plutil -convert binary1 $<

bundle-rm-fat-library :
	$(RM) $(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME)

$(BUILT_PRODUCTS_DIR)/$(FRAMEWORKBUNDLE)/$(FRAMEWORK_NAME) : $(addprefix $(MAKER_BUILDROOT_DIR)/, $(addsuffix /$(FRAMEWORKBUNDLE)$(INSTALLED_LIB),$(ARCHS)))
	xcrun -sdk iphoneos lipo -create $^ -o $@

$(FRAMEWORKBUNDLE).tar.bz2 :
	$(RM) $(FRAMEWORKBUNDLE).tar.bz2
	tar -C $(BUILT_PRODUCTS_DIR) -cjf $(FRAMEWORKBUNDLE).tar.bz2 $(FRAMEWORKBUNDLE)

