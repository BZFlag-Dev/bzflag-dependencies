# BZFlag Dependencies

This repository contains third-party libraries that are needed to build BZFlag on Windows using
Visual C++.


## Upstream

Here is a list of the upstream source locations:

* [c-ares](https://github.com/c-ares/c-ares)
* [libcurl](https://github.com/curl/curl)
* [PDCurses](http://sourceforge.net/projects/pdcurses/files/pdcurses/)
* regex - Looks like it was some version from NetBSD. Haven't yet found the ideal location to pull a
  new version from, so I'm using what we had.
* [zlib](https://github.com/madler/zlib)

## Building the libraries

Batch files to build for either Visual C++ 2010 or 2015 are provided. Run the buildVC2010.bat or
buildVC2015.bat file and it should build the libraries. Output will go into a folder such as
output-release-x86. Run a 'git clean -x -f -d' before switching between Visual C++ versions.
