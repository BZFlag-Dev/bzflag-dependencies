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
* [libpng](https://git.code.sf.net/p/libpng/)
* [GLEW](http://glew.sourceforge.net/)
* [SDL2](https://libsdl.org/)
* [zlib](https://github.com/madler/zlib)

## Building the libraries

A batch file to build for Visual C++ 2017 is provided. Run the buildVC2017.bat file and it should
build the libraries. Output will go into a folder such as output-release-x86. Run a 
'git clean -x -f -d' before switching between Visual C++ versions.

## Using the libraries

Create an environment variable called BZ_DEPS that points to the directory that the output
directories are contained within. For instance, if output-release-x86 is at
'D:\bzflag-dependencies\output-release-x86', then BZ_DEPS should be 'D:\bzflag-dependencies\'.

## Updating the libraries

When new versions of these dependencies are released, we should update our copies. There are two ways this is accomplished in this repository. For libpng and zlib, which have properly tagged git repositories, this is done with the `git subtree` command. Replace TAG with the tag you wish to pull. 

git subtree pull --prefix src/zlib https://github.com/madler/zlib TAG --squash

For the others, just delete the contents and replace with the new contents of the source tars.