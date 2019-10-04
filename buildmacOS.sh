#!/bin/bash

function buildDeps {
	ARCH=$1
	CONF=$2

	ORIGROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	SRCROOT=$ORIGROOT/src
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

	echo "=============================="
	echo "Building libpng ($CONF)"
	echo "=============================="

	cd $SRCROOT/libpng

	# libpng appears to have no debug configuration
	./autogen.sh > /dev/null 2>&1
	./configure --prefix=$OUTPUTROOT --disable-shared &&
	make -j`sysctl -n hw.ncpu` &&
	make install &&
	cp LICENSE $ORIGROOT/dependencies/licenses/libpng.txt &&
	make distclean

	THIS_RESULT=$?
	if [[ -z $LIBPNG_RESULT || $LIBPNG_RESULT == 0 ]] ; then LIBPNG_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	echo "=============================="
	echo "Building c-ares ($CONF)"
	echo "=============================="

	cd $SRCROOT/c-ares

	if [[ $CONF == "debug" ]] ; then
		./configure --prefix=$OUTPUTROOT --disable-shared
	else
		./configure --prefix=$OUTPUTROOT --disable-shared --enable-debug
	fi &&
	make -j`sysctl -n hw.ncpu` &&
	make install &&
	cp LICENSE.md $ORIGROOT/dependencies/licenses/c-ares.txt &&
	make distclean

	THIS_RESULT=$?
	if [[ -z $CARES_RESULT || $CARES_RESULT == 0 ]] ; then CARES_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	echo "=============================="
	echo "Building GLEW ($CONF)"
	echo "=============================="

	cd $SRCROOT/glew

	if [[ $CONF == "debug" ]] ; then
		make glew.lib.static GLEW_DEST=$OUTPUTROOT STRIP= &&
		make install GLEW_DEST=$OUTPUTROOT STRIP=
	else
		make glew.lib.static GLEW_DEST=$OUTPUTROOT &&
		make install GLEW_DEST=$OUTPUTROOT
	fi &&
	rm $OUTPUTROOT/lib/libGLEW*.dylib && # the makefile doesn't seem to respect the static-only build configuration
	cp LICENSE.txt $ORIGROOT/dependencies/licenses/GLEW.txt &&
	make clean

	THIS_RESULT=$?
	if [[ -z $GLEW_RESULT || $GLEW_RESULT == 0 ]] ; then GLEW_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	echo "=============================="
	echo "Building SDL2 ($CONF)"
	echo "=============================="

	cd $SRCROOT/SDL2

	# SDL2 appears to have no debug configuration
	./configure --prefix=$OUTPUTROOT --disable-shared &&
	make -j`sysctl -n hw.ncpu` &&
	make install &&
	cp COPYING.txt $ORIGROOT/dependencies/licenses/SDL2.txt &&
	make distclean

	THIS_RESULT=$?
	if [[ -z $SDL2_RESULT || $SDL2_RESULT == 0 ]] ; then SDL2_RESULT=$THIS_RESULT ; fi
	unset THIS_RESULT

	echo

	echo "=============================="
	echo "Copying glm ($CONF)"
	echo "=============================="

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

# build 64-bit dependencies for macOS (no reason to support 32-bit anymore)
buildDeps x86_64 release
buildDeps x86_64 debug

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
