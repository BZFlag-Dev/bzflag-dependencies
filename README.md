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
* [libpng](https:/github.com/pnggroup/libpng)
* [GLEW](http://glew.sourceforge.net/)
* [SDL2](https://libsdl.org/)
* [zlib](https://github.com/madler/zlib)

When new versions of these dependencies are released, we should update our copies. Just delete the contents and replace
with the new contents of the source tars (not zips). This should be done on a Linux or macOS system so that the execute
permission on scripts is preserved.

## Requirements

On Windows, you must have Visual Studio 2017 installed with at least "Desktop development with C++".

For macOS, you must have Xcode installed. Additionally, autoconf and automake from homebrew are currently needed to
build c-ares.

## Building the libraries

On Windows, run buildVC2017.bat. On macOS, run buildmacOS.sh.

## Using the libraries

Copy the "dependencies" folder to the game source code directory. It should be alongside include and src.
