# connect_c_ios8.patch
The fix for the connectx function not available in iOS8 does not fix the problem,
it just allows curl to build so we can use it in iOS9, 10 & 11. It will fail on
an iOS8 device.

The reason for not fixing it was:

1. I'm being lazy (not much return for the effort)
2. There appears to be an effort upstream to fix it (https://github.com/curl/curl/issues/1330)
3. There is no easy fix, curl was not designed to build on one version of OSX/iOS and run on
   another (where a new function may be unavailable).

So if support for iOS8 is really required, this patch will have to be revisited. Hopefully
Apple will deprecate support of iOS8 in Xcode first.

(A real fix would provide a weak implementation of connectx that just calls connect)
