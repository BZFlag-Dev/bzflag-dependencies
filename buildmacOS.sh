#!/bin/bash

ORIGROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRCROOT=$ORIGROOT/src

# check for spaces in path
ESCAPEDORIGROOT=$(printf %q "$ORIGROOT")
if [[ "$ORIGROOT" != "$ESCAPEDORIGROOT" ]] ; then
	echo "This script has detected that the path to its parent directory contains spaces"
	echo "or other special characters. The build systems of some of our dependencies do"
	echo "not support escaped paths, so building is likely to fail. Please move the"
	echo "parent directory of this script to a location without spaces or other special"
	echo "characters in its path, then try building again."
	echo
	echo "Press enter to continue anyway, or Ctrl-C to cancel."
	read -rs
	echo
fi

function printHeading {
	if [[ "$#" -gt 0 ]] ; then
		NUM_CHARS="$(echo -n "$1" | wc -c)"
		while [[ "$NUM_CHARS" -gt 0 ]] ; do printf "=" ; NUM_CHARS="$(($NUM_CHARS - 1))" ; done ; echo
		echo $1
		NUM_CHARS="$(echo -n "$1" | wc -c)"
		while [[ "$NUM_CHARS" -gt 0 ]] ; do printf "=" ; NUM_CHARS="$(($NUM_CHARS - 1))" ; done ; echo
	fi
}

function buildDeps {
	ARCH=$1
	CONF=$2

	OUTPUTROOT=$ORIGROOT/dependencies/output-macOS-$CONF-$ARCH

	mkdir -p $OUTPUTROOT
	mkdir -p $OUTPUTROOT/bin
	mkdir -p $OUTPUTROOT/lib
	mkdir -p $OUTPUTROOT/include
	mkdir -p $ORIGROOT/dependencies/licenses

	export MACOSX_DEPLOYMENT_TARGET=10.9
	export CPPFLAGS="-I$OUTPUTROOT/include"
	export CFLAGS="-arch $ARCH"
	export CXXFLAGS="-arch $ARCH"
	export LDFLAGS="-L$OUTPUTROOT/lib -arch $ARCH"

	if [[ "$ARCH" == x86_64 ]] ; then
		BUILD_HOST=x86_64-apple-darwin$(uname -r)
	elif [[ "$ARCH" == arm64 ]] ; then
		BUILD_HOST=arm-apple-darwin$(uname -r)
	else
		echo Unknown architecture type $ARCH. Exiting.
		exit
	fi

	############################################
	printHeading "Building libpng ($ARCH $CONF)"
	############################################

	cd $SRCROOT/libpng

	# libpng appears to have no debug configuration
	./configure --prefix=$OUTPUTROOT --host=$BUILD_HOST --disable-shared &&
	make -j`sysctl -n hw.ncpu` &&
	make install &&
	cp LICENSE $ORIGROOT/dependencies/licenses/libpng.txt &&
	make distclean

	THIS_RESULT=$?
	if [[ -z $LIBPNG_RESULT || $LIBPNG_RESULT == 0 ]] ; then LIBPNG_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	############################################
	printHeading "Building c-ares ($ARCH $CONF)"
	############################################

	cd $SRCROOT/c-ares

	cp include/ares_build.h include/ares_build.h.bak &&
	if [[ $CONF == "Debug" ]] ; then
		./configure --prefix=$OUTPUTROOT --host=$BUILD_HOST --disable-shared --disable-tests --enable-debug
	else
		./configure --prefix=$OUTPUTROOT --host=$BUILD_HOST --disable-shared --disable-tests
	fi &&
	make -j`sysctl -n hw.ncpu` &&
	make install &&
	mv include/ares_build.h.bak include/ares_build.h &&
	cp LICENSE.md $ORIGROOT/dependencies/licenses/c-ares.txt &&
	make clean

	THIS_RESULT=$?
	if [[ -z $CARES_RESULT || $CARES_RESULT == 0 ]] ; then CARES_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	##########################################
	printHeading "Building GLEW ($ARCH $CONF)"
	##########################################

	cd $SRCROOT/glew

	if [[ $CONF == "Debug" ]] ; then
		make glew.lib.static GLEW_DEST=$OUTPUTROOT SYSTEM=darwin CFLAGS.EXTRA="$CFLAGS" STRIP= &&
		make install GLEW_DEST=$OUTPUTROOT STRIP=
	else
		make glew.lib.static GLEW_DEST=$OUTPUTROOT SYSTEM=darwin CFLAGS.EXTRA="$CFLAGS" &&
		make install GLEW_DEST=$OUTPUTROOT
	fi &&
	rm $OUTPUTROOT/lib/libGLEW*.dylib && # the makefile doesn't seem to respect the static-only build configuration
	cp LICENSE.txt $ORIGROOT/dependencies/licenses/GLEW.txt &&
	make clean

	THIS_RESULT=$?
	if [[ -z $GLEW_RESULT || $GLEW_RESULT == 0 ]] ; then GLEW_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	##########################################
	printHeading "Building SDL2 ($ARCH $CONF)"
	##########################################

	cd $SRCROOT/SDL2

	cp include/SDL_config.h include/SDL_config.h.bak &&
	# SDL2 appears to have no debug configuration
	./configure --prefix=$OUTPUTROOT --host=$BUILD_HOST --disable-shared &&
	make -j`sysctl -n hw.ncpu` &&
	make install &&
	mv include/SDL_config.h.bak include/SDL_config.h &&
	cp COPYING.txt $ORIGROOT/dependencies/licenses/SDL2.txt &&
	make distclean

	THIS_RESULT=$?
	if [[ -z $SDL2_RESULT || $SDL2_RESULT == 0 ]] ; then SDL2_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	########################################
	printHeading "Copying glm ($ARCH $CONF)"
	########################################

	cd $SRCROOT/glm

	# glm is a header-only library, so just copy the files
	cp -R glm $OUTPUTROOT/include/ &&
	cp copying.txt $ORIGROOT/dependencies/licenses/glm.txt

	THIS_RESULT=$?
	if [[ -z $GLM_RESULT || $GLM_RESULT == 0 ]] ; then GLM_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	cd $ORIGROOT
}

# build these configurations
buildDeps x86_64 Release
buildDeps x86_64 Debug
buildDeps arm64 Release
buildDeps arm64 Debug

echo "#######################"
echo "# Final build results #"
echo "#######################"

if [[ $LIBPNG_RESULT == 0 ]] ; then
	echo libpng ................. SUCCESS!
else
	echo libpng ................. FAILED!
fi
if [[ $CARES_RESULT == 0 ]] ; then
	echo c-ares ................. SUCCESS!
else
	echo c-ares ................. FAILED!
fi
if [[ $GLEW_RESULT == 0 ]] ; then
	echo GLEW ................... SUCCESS!
else
	echo GLEW ................... FAILED!
fi
if [[ $SDL2_RESULT == 0 ]] ; then
	echo SDL2 ................... SUCCESS!
else
	echo SDL2 ................... FAILED!
fi
if [[ $GLM_RESULT == 0 ]] ; then
	echo glm .................... SUCCESS!
else
	echo glm .................... FAILED!
fi

exit
