@echo off

:: FIXME: 64-bit builds DO NOT work and instead seem to build as 32-bit or just fail.
:: If you pass x64 as the first argument to the batch script, it would (in theory) build 64-bit versions of the libraries.
::   C:\> buildVC2010.bat x64

if not "%DevEnvDir%" == "" (
	echo.
	echo Please do not run from an existing Visual Studio command prompt or with a prompt from a previous run.
	goto:eof
)

set ARCH=x86
if "%1" == "x64" set ARCH=x64

if exist "%ProgramFiles%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" (
	call "%ProgramFiles%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" %ARCH%
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" (
	call "%ProgramFiles(x86)%\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" %ARCH%
) else (
	echo Unable to locate vcvarsall.bat, aborting
	pause
	goto:eof
)


call:buildDeps %ARCH% release
call:buildDeps %ARCH% debug

pause

goto:eof


:: The buildDeps function lets us build multiple configurations (release and debug) for the current architecture

:buildDeps
set ARCH=%~1
set CONF=%~2

%~d0
set origroot=%~dp0
set srcroot=%origroot%src
set outputroot=%origroot%output-%CONF%-%ARCH%

if not exist %outputroot% mkdir %outputroot%
if not exist %outputroot%\bin mkdir %outputroot%\bin
if not exist %outputroot%\lib mkdir %outputroot%\lib
if not exist %outputroot%\include mkdir %outputroot%\include

echo ==============================
echo Building PDCurses
echo ==============================

cd %srcroot%\pdcurses\win32
:: Not sure if we need to clean between builds
::nmake -f vcwin32.mak clean
::del none pdcurses.ilk

if "%CONF%" == "debug" (
	nmake -f vcwin32.mak DEBUG= UTF8= pdcurses.lib
) else (
	nmake -f vcwin32.mak UTF8= pdcurses.lib
)

set PDCURSES_RESULT=%ERRORLEVEL%

if %PDCURSES_RESULT% == 0 (
	cd %srcroot%\pdcurses
	copy win32\*.lib %outputroot%\lib\
	copy *.h %outputroot%\include\
)

echo(
echo ==============================
echo Building zlib
echo ==============================

cd %srcroot%\zlib
:: Not sure if we need to clean between builds
::nmake -f win32\Makefile.msc clean
nmake -f win32\Makefile.msc zdll.lib

set ZLIB_RESULT=%ERRORLEVEL%

if %ZLIB_RESULT% == 0 (
	cd %srcroot%\zlib
	copy *.dll %outputroot%\bin\
	:: The curl build expects the zdll.* files to be named zlib.*
	copy zdll.lib %outputroot%\lib\zlib.lib
	if "%CONF%" == "debug" (
		copy zdll.pdb %outputroot%\lib\zlib.pbd
	)
	copy zdll.exp %outputroot%\lib\zlib.exp
	copy *.h %outputroot%\include\
)

echo(
echo ==============================
echo Building c-ares
echo ==============================

cd %srcroot%\c-ares

call buildconf.bat
:: Not sure if we need to clean between builds
::nmake -f Makefile.msvc clean
nmake -f Makefile.msvc CFG=dll-%CONF% c-ares
set CARES_RESULT=%ERRORLEVEL%
cd %srcroot%\c-ares

:: Copy the necessary files to the output directory
if %CARES_RESULT% == 0 (
	copy ares.h "%outputroot%\include\"
	copy ares_build.h "%outputroot%\include\"
	copy ares_rules.h "%outputroot%\include\"
	copy ares_version.h "%outputroot%\include\"
	
	copy "msvc100\cares\dll-%CONF%\*.dll" "%outputroot%\bin\"
	copy "msvc100\cares\dll-%CONF%\*.lib" "%outputroot%\lib\"
	copy "msvc100\cares\dll-%CONF%\*.exp" "%outputroot%\lib\"
)

echo(
echo ==============================
echo Building libcurl
echo ==============================

cd %srcroot%\curl

call buildconf.bat

cd %srcroot%\curl\winbuild

if "%CONF%" == "debug" (
	nmake -f Makefile.vc mode=dll VC=10 WITH_DEVEL=%outputroot% WITH_ZLIB=dll WITH_CARES=dll ENABLE_IDN=no ENABLE_WINSSL=yes GEN_PDB=no DEBUG=yes MACHINE=%ARCH%
) else (
	nmake -f Makefile.vc mode=dll VC=10 WITH_DEVEL=%outputroot% WITH_ZLIB=dll WITH_CARES=dll ENABLE_IDN=no ENABLE_WINSSL=yes GEN_PDB=no DEBUG=no MACHINE=%ARCH%
)

set CURL_RESULT=%ERRORLEVEL%

if %CURL_RESULT% == 0 (
    cd %srcroot%\curl\builds\libcurl-vc10-%ARCH%-%CONF%-dll-cares-dll-zlib-dll-ipv6-sspi-winssl
    copy bin\*.dll %outputroot%\bin\
    copy lib\*.lib %outputroot%\lib\
    copy lib\*.exp %outputroot%\lib\
    copy lib\*.pdb %outputroot%\lib\
    if not exist %outputroot%\include\curl mkdir %outputroot%\include\curl
    copy include\curl\*.h %outputroot%\include\curl\
)

echo(
echo ==============================
echo Building regex
echo ==============================

cd %srcroot%\regex
if "%ARCH%" == "x86" (
	msbuild regex.sln /property:Configuration=%CONF% /property:Platform=Win32
) else (
	msbuild regex.sln /property:Configuration=%CONF% /property:Platform=x64
)

set REGEX_RESULT=%ERRORLEVEL%

if %REGEX_RESULT% == 0 (
	cd %srcroot%\regex
	if "%ARCH%" == "x86" (
		copy regex_Win32_%CONF%\regex.lib %outputroot%\lib
	) else (
		copy regex_x64_%CONF%\regex.lib %outputroot%\lib
	)
	copy regex.h %outputroot%\include
)

echo(
echo ==============================
echo Building SDL2
echo ==============================

cd "%srcroot%\SDL2\VisualC"
if "%ARCH%" == "x86" (
	msbuild SDL.sln /property:Configuration=%CONF% /property:Platform=Win32
) else (
	msbuild SDL.sln /property:Configuration=%CONF% /property:Platform=x64
)

set SDL2_RESULT=%ERRORLEVEL%

if %SDL2_RESULT% == 0 (
	cd "%srcroot%\SDL2"
	if "%ARCH%" == "x86" (
		copy "VisualC\Win32\%CONF%\SDL2.dll" "%outputroot%\bin"
		copy "VisualC\Win32\%CONF%\SDL2.lib" "%outputroot%\lib"
		copy "VisualC\Win32\%CONF%\SDL2.pdb" "%outputroot%\lib"
		copy "VisualC\Win32\%CONF%\SDL2main.lib" "%outputroot%\lib"
	) else (
		copy "VisualC\x64\%CONF%\SDL2.dll" "%outputroot%\bin"
		copy "VisualC\x64\%CONF%\SDL2.lib" "%outputroot%\lib"
		copy "VisualC\x64\%CONF%\SDL2.pdb" "%outputroot%\lib"
		copy "VisualC\x64\%CONF%\SDL2main.lib" "%outputroot%\lib"
	)
	mkdir "%outputroot%\include\SDL2"
	copy "include\*.h" "%outputroot%\include\SDL2\"
)

echo(
echo(
echo #######################
echo # Final build results #
echo #######################
echo(
if %PDCURSES_RESULT% == 0 (
	echo PDCurses ............... SUCCESS!
) else (
	echo PDCurses ............... FAILED!
)
if %PDCURSES_RESULT% == 0 (
	echo zlib ................... SUCCESS!
) else (
	echo zlib ................... FAILED!
)
if %CARES_RESULT% == 0 (
	echo c-ares ................. SUCCESS!
) else (
	echo c-ares ................. FAILED!
)
if %CURL_RESULT% == 0 (
	echo curl ................... SUCCESS!
) else (
	echo curl ................... FAILED!
)
if %REGEX_RESULT% == 0 (
	echo regex .................. SUCCESS!
) else (
	echo regex .................. FAILED!
)
if %SDL2_RESULT% == 0 (
	echo SDL2 ................... SUCCESS!
) else (
	echo SDL2 ................... FAILED!
)

cd %origroot%
goto:eof
