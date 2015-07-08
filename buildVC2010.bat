@echo off

set origroot=%~dp0
set srcroot=%origroot%\src
set outputroot=%origroot%\output-release-x86

if not "%DevEnvDir%" == "" (
	echo.
	echo Please do not run from an existing Visual Studio command prompt or with a prompt from a previous run.
	goto end
)

call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86

if not exist %outputroot% mkdir %outputroot%
if not exist %outputroot%\bin mkdir %outputroot%\bin
if not exist %outputroot%\lib mkdir %outputroot%\lib
if not exist %outputroot%\include mkdir %outputroot%\include

echo ==============================
echo Building PDCurses
echo ==============================

cd %srcroot%\pdcurses\win32
nmake -f vcwin32.mak DLL= UTF8= pdcurses.dll

set PDCURSES_RESULT=%ERRORLEVEL%

if %PDCURSES_RESULT% == 0 (
	cd %srcroot%\pdcurses
	copy win32\*.dll %outputroot%\bin\
	copy win32\*.lib %outputroot%\lib\
	copy win32\*.exp %outputroot%\lib\
	copy *.h %outputroot%\include\
)

echo(
echo ==============================
echo Building zlib
echo ==============================

cd %srcroot%\zlib
nmake -f win32\Makefile.msc zdll.lib

set ZLIB_RESULT=%ERRORLEVEL%

if %ZLIB_RESULT% == 0 (
	cd %srcroot%\zlib
	copy *.dll %outputroot%\bin\
	rem The curl build expects the zdll.* files to be named zlib.*
	copy zdll.lib %outputroot%\lib\zlib.lib
	copy zdll.exp %outputroot%\lib\zlib.exp
	copy *.h %outputroot%\include\
)

echo(
echo ==============================
echo Building c-ares
echo ==============================

set INSTALL_DIR=%outputroot%

cd %srcroot%\c-ares

call buildconf.bat
rem Rename the INSTALL file so that the nmake install target works...
rename INSTALL INSTALL.temp
nmake -f Makefile.msvc CFG=dll-release install
set CARES_RESULT=%ERRORLEVEL%
cd %srcroot%\c-ares
rename INSTALL.temp INSTALL

rem Move the DLL files to the bin directory
if %CARES_RESULT% == 0 (
    move "%outputroot%\lib\*.dll" "%outputroot%\bin\"
)

echo(
echo ==============================
echo Building libcurl
echo ==============================

cd %srcroot%\curl

call buildconf.bat

cd %srcroot%\curl\winbuild

nmake -f Makefile.vc mode=dll VC=10 WITH_DEVEL=%outputroot% WITH_ZLIB=dll WITH_CARES=dll ENABLE_IDN=no ENABLE_WINSSL=yes GEN_PDB=no DEBUG=no MACHINE=x86

set CURL_RESULT=%ERRORLEVEL%

if %CURL_RESULT% == 0 (
    cd %srcroot%\curl\builds\libcurl-vc10-x86-release-dll-cares-dll-zlib-dll-ipv6-sspi-winssl
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
devenv /build release /project regex regex.sln

set REGEX_RESULT=%ERRORLEVEL%

if %REGEX_RESULT% == 0 (
    cd %srcroot%\regex
    copy regex_Win32_Release\regex.lib %outputroot%\lib
    copy regex.h %outputroot%\include
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

pause

:end

cd %origroot%
