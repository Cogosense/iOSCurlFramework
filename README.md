# A Curl library framework for iOS [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

More information on the [curl home page](https://curl.haxx.se/)

The Makefile in this project creates a fat iOS framework bundle that supports the following architectures:

* arm64
* armv7
* armv7s
* i386
* x86_64

It is suitable for using on all iOS devices and simulators.

## Carthage

The Makefile was refactored to work better with the new Xcode10 build system. The **iOSCurlFramework.xcodeproj**
file was updated to include a shared Cocoa Touch Framework target **curl**. This is required
by [Carthage](https://github.com/Carthage/Carthage).

To add **iOSCurlFramework** to your project, first create a *Cartfile* in your project's root
with the following contents:

    github "Cogosense/iOSCurlFramework"

Then build with Carthage:

    carthage update

More details on adding frameworks to a project can be found [here](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).

## Legacy Makefile (deprecated)

**Makefile.legacy** is the original Makefile. It supports curl v7.61.1 and won't be updated any further.

To continue using the legacy Makefile use the **-f** option to make.

    make -f Makefile.legacy build

The xcodeproj file still contains the External Build Tool target **curl.framework** which
invokes make with the **-f Makefile.legacy** option. Existing usage of this project should continue
to work.
