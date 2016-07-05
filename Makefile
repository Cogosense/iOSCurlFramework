SHELL = /bin/bash
NAME = curl
VERSION = 7.42.1
TARBALL = $(NAME)-$(VERSION).tar.gz
TOPDIR = $(PWD)
SRCDIR = $(NAME)-$(VERSION)
ARM_ARCH = arm-apple-darwin
X86_ARCH = i386-apple-darwin
ARM_64_ARCH = aarch64-apple-darwin
X86_64_ARCH = x86_64-apple-darwin
FRAMEWORK_VERSION = A
FRAMEWORK_NAME = curl
FRAMEWORKDIR = $(FRAMEWORK_NAME).framework
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
#ifdef __arm__\n
#include "curlbuild_$(ARM_ARCH).h"\n
#endif\n
#ifdef __x86_64__\n
#include "curlbuild_$(X86_64_ARCH).h"\n
#endif\n
#ifdef __i386__\n
#include "curlbuild_$(X86_ARCH).h"\n
#endif\n
#endif\n
endef

all : $(FRAMEWORKDIR)

distclean : clean
	$(RM) $(TARBALL)

clean : mostlyclean
	$(RM) -r $(FRAMEWORKDIR)

mostlyclean :
	$(RM) Info.plist
	$(RM) -r $(SRCDIR)

$(TARBALL) :
	curl -L --retry 10 -s -o $@ $(DOWNLOAD_URL) || $(RM) $@

$(SRCDIR)/configure : $(TARBALL)
	tar xf $(TARBALL)

#
# Because of the way curl enbeds the architecture into the code
# using generated header files, the 32bit and 64bit code must be
# built seperately and then combined later using lipo
#
$(SRCDIR)/$(ARM_ARCH)/Makefile : $(SRCDIR)/configure
	[ -d $(SRCDIR)/$(ARM_ARCH) ] || mkdir $(SRCDIR)/$(ARM_ARCH)
	cd $(SRCDIR)/$(ARM_ARCH) && \
	    ../configure \
		--prefix=/$(FRAMEWORKDIR) \
		--host=$(ARM_ARCH) \
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
		CC='xcrun --sdk iphoneos clang -fembed-bitcode -miphoneos-version-min=6.1 -arch armv7' \
		CPP='xcrun --sdk iphoneos clang -arch arm -E' \
		AR='xcrun --sdk iphoneos ar' \
		LD='xcrun --sdk iphoneos ld' \
		LIPO='xcrun --sdk iphoneos lipo' \
		OTOOL='xcrun --sdk iphoneos otool' \
		STRIP='xcrun --sdk iphoneos strip' \
		NM='xcrun --sdk iphoneos nm' \
		LIBTOOL='xcrun --sdk iphoneos libtool'

$(SRCDIR)/$(ARM_64_ARCH)/Makefile : $(SRCDIR)/configure
	[ -d $(SRCDIR)/$(ARM_64_ARCH) ] || mkdir $(SRCDIR)/$(ARM_64_ARCH)
	cd $(SRCDIR)/$(ARM_64_ARCH) && \
	    ../configure \
		--prefix=/$(FRAMEWORKDIR) \
		--host=$(ARM_64_ARCH) \
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
		CC='xcrun --sdk iphoneos clang -fembed-bitcode -miphoneos-version-min=6.1 -arch arm64' \
		CPP='xcrun --sdk iphoneos clang -arch arm64 -E' \
		AR='xcrun --sdk iphoneos ar' \
		LD='xcrun --sdk iphoneos ld' \
		LIPO='xcrun --sdk iphoneos lipo' \
		OTOOL='xcrun --sdk iphoneos otool' \
		STRIP='xcrun --sdk iphoneos strip' \
		NM='xcrun --sdk iphoneos nm' \
		LIBTOOL='xcrun --sdk iphoneos libtool'

$(SRCDIR)/$(X86_ARCH)/Makefile : $(SRCDIR)/configure
	[ -d $(SRCDIR)/$(X86_ARCH) ] || mkdir $(SRCDIR)/$(X86_ARCH)
	cd $(SRCDIR)/$(X86_ARCH) && \
	    ../configure \
		--prefix=/$(FRAMEWORKDIR) \
		--host=$(X86_ARCH) \
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
		--without-libidn \
		CC='xcrun --sdk iphonesimulator clang -fembed-bitcode -miphoneos-version-min=6.1 -arch i386' \
		CPP='xcrun --sdk iphonesimulator clang -arch i386 -E' \
		AR='xcrun --sdk iphonesimulator ar' \
		LD='xcrun --sdk iphonesimulator ld' \
		LIPO='xcrun --sdk iphonesimulator lipo' \
		OTOOL='xcrun --sdk iphonesimulator otool' \
		STRIP='xcrun --sdk iphonesimulator strip' \
		NM='xcrun --sdk iphonesimulator nm' \
		LIBTOOL='xcrun --sdk iphonesimulator libtool'

$(SRCDIR)/$(X86_64_ARCH)/Makefile : $(SRCDIR)/configure
	[ -d $(SRCDIR)/$(X86_64_ARCH) ] || mkdir $(SRCDIR)/$(X86_64_ARCH)
	cd $(SRCDIR)/$(X86_64_ARCH) && \
	    ../configure \
		--prefix=/$(FRAMEWORKDIR) \
		--host=$(X86_64_ARCH) \
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
		--without-libidn \
		CC='xcrun --sdk iphonesimulator clang -fembed-bitcode -miphoneos-version-min=6.1 -arch x86_64' \
		CPP='xcrun --sdk iphonesimulator clang -arch x86_64 -E' \
		AR='xcrun --sdk iphonesimulator ar' \
		LD='xcrun --sdk iphonesimulator ld' \
		LIPO='xcrun --sdk iphonesimulator lipo' \
		OTOOL='xcrun --sdk iphonesimulator otool' \
		STRIP='xcrun --sdk iphonesimulator strip' \
		NM='xcrun --sdk iphonesimulator nm' \
		LIBTOOL='xcrun --sdk iphonesimulator libtool'

export Info_plist

Info.plist : Makefile
	echo -e $$Info_plist > $@

$(SRCDIR)/$(ARM_ARCH)/$(FRAMEWORKDIR) : $(SRCDIR)/$(ARM_ARCH)/Makefile
	make -C $(SRCDIR)/$(ARM_ARCH) DESTDIR=$(TOPDIR)/$(SRCDIR)/$(ARM_ARCH) install

$(SRCDIR)/$(X86_ARCH)/$(FRAMEWORKDIR) : $(SRCDIR)/$(X86_ARCH)/Makefile
	make -C $(SRCDIR)/$(X86_ARCH) DESTDIR=$(TOPDIR)/$(SRCDIR)/$(X86_ARCH) install

$(SRCDIR)/$(ARM_64_ARCH)/$(FRAMEWORKDIR) : $(SRCDIR)/$(ARM_64_ARCH)/Makefile
	make -C $(SRCDIR)/$(ARM_64_ARCH) DESTDIR=$(TOPDIR)/$(SRCDIR)/$(ARM_64_ARCH) install

$(SRCDIR)/$(X86_64_ARCH)/$(FRAMEWORKDIR) : $(SRCDIR)/$(X86_64_ARCH)/Makefile
	make -C $(SRCDIR)/$(X86_64_ARCH) DESTDIR=$(TOPDIR)/$(SRCDIR)/$(X86_64_ARCH) install

export curlbuild_h

$(FRAMEWORKDIR) : $(SRCDIR)/$(ARM_ARCH)/$(FRAMEWORKDIR) $(SRCDIR)/$(X86_ARCH)/$(FRAMEWORKDIR) $(SRCDIR)/$(ARM_64_ARCH)/$(FRAMEWORKDIR) $(SRCDIR)/$(X86_64_ARCH)/$(FRAMEWORKDIR) Info.plist
	$(RM) -r $(FRAMEWORKDIR)
	mkdir $(FRAMEWORKDIR)
	mkdir $(FRAMEWORKDIR)/Versions
	mkdir $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)
	mkdir $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Resources
	cp $(TOPDIR)/Info.plist $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Resources/
	cp -R $(TOPDIR)/$(SRCDIR)/$(ARM_ARCH)/$(FRAMEWORKDIR)/include/curl $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers
	$(RM) $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild.h
	cp $(TOPDIR)/$(SRCDIR)/$(ARM_ARCH)/$(FRAMEWORKDIR)/include/curl/curlbuild.h $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild_$(ARM_ARCH).h 
	cp $(TOPDIR)/$(SRCDIR)/$(ARM_64_ARCH)/$(FRAMEWORKDIR)/include/curl/curlbuild.h $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild_$(ARM_64_ARCH).h 
	cp $(TOPDIR)/$(SRCDIR)/$(X86_ARCH)/$(FRAMEWORKDIR)/include/curl/curlbuild.h $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild_$(X86_ARCH).h 
	cp $(TOPDIR)/$(SRCDIR)/$(X86_64_ARCH)/$(FRAMEWORKDIR)/include/curl/curlbuild.h $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild_$(X86_64_ARCH).h 
	echo -e $$curlbuild_h > $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Headers/curlbuild.h
	cp -R $(TOPDIR)/$(SRCDIR)/$(ARM_ARCH)/$(FRAMEWORKDIR)/share $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/Documentation ; \
	xcrun -sdk iphoneos lipo -create \
	    $(TOPDIR)/$(SRCDIR)/$(ARM_ARCH)/$(FRAMEWORKDIR)/lib/libcurl.a \
	    $(TOPDIR)/$(SRCDIR)/$(X86_ARCH)/$(FRAMEWORKDIR)/lib/libcurl.a \
	    $(TOPDIR)/$(SRCDIR)/$(ARM_64_ARCH)/$(FRAMEWORKDIR)/lib/libcurl.a \
	    $(TOPDIR)/$(SRCDIR)/$(X86_64_ARCH)/$(FRAMEWORKDIR)/lib/libcurl.a \
	    -o $(FRAMEWORKDIR)/Versions/$(FRAMEWORK_VERSION)/$(FRAMEWORK_NAME)
	cd $(FRAMEWORKDIR) && set -e ; \
	ln -s $(FRAMEWORK_VERSION) Versions/Current ; \
	ln -s Versions/Current/Headers Headers ; \
	ln -s Versions/Current/Resources Resources ; \
	ln -s Versions/Current/Documentation Documentation ; \
	ln -s Versions/Current/$(FRAMEWORK_NAME) $(FRAMEWORK_NAME)

