# BZFlag Dependencies

This repository contains third-party libraries that are needed to build BZFlag on Windows using Visual C++.


## Upstream

Here is a list of the upstream source locations:

* [c-ares](https://github.com/bagder/c-ares.git)
* [libcurl](https://github.com/bagder/curl.git)
* [PDCurses](http://sourceforge.net/projects/pdcurses/files/pdcurses/)
* regex - Looks like it was some version from NetBSD. Haven't yet found the ideal location to pull a new version from, so I'm using what we had.
* [zlib](https://github.com/madler/zlib.git)

## Building the libraries

Building these libraries requires Visual C++ 2010 at present, since this is the compiler that BZFlag 2.4 uses. Run the buildVC210.bat file and it should build the libraries. Output will go into a folder such as output-release-x86.
