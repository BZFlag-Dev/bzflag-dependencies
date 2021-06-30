@echo off

:: Adjust this if you have an edition other than Community
set VSEDITION=Community



if not "%DevEnvDir%" == "" (
	echo.
	echo Please do not run from an existing Visual Studio command prompt.
	goto:eof
)

:: The first argument can specify which architecture to build the dependencies for.
:: If none is provided, both x86 and x64 will be compiled.
if "%1" == "x86" (
	set ARCH=x86
) else if "%1" == "x64" (
	set ARCH=x64
) else (
	setlocal
	call buildVC2017.bat x86 /nopause
	endlocal
	setlocal
	call buildVC2017.bat x64 /nopause
	endlocal
	pause
	goto:eof
)

:: The second argument can disable pausing at the end of the build.
if "%2" == "/nopause" (
	set PAUSE=0
) else (
	set PAUSE=1
)


:: Load the Visual Studio command prompt vars
if exist "%ProgramFiles%\Microsoft Visual Studio\2017\%VSEDITION%\VC\Auxiliary\Build\vcvarsall.bat" (
	call "%ProgramFiles%\Microsoft Visual Studio\2017\%VSEDITION%\VC\Auxiliary\Build\vcvarsall.bat" %ARCH%
) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\%VSEDITION%\VC\Auxiliary\Build\vcvarsall.bat" (
	call "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\%VSEDITION%\VC\Auxiliary\Build\vcvarsall.bat" %ARCH%
) else (
	echo Unable to locate vcvarsall.bat, aborting
	pause
	goto:eof
)

:: Compile the release and debug version for the current architecture
call:buildDeps %ARCH% release
call:buildDeps %ARCH% debug

if %PAUSE% == 1 pause

goto:eof


:: The buildDeps function lets us build multiple configurations (release and debug) for the current architecture

:buildDeps
set ARCH=%~1
set CONF=%~2

%~d0
set origroot=%~dp0
set srcroot=%origroot%src
set outputroot=%origroot%dependencies\output-windows-%CONF%-%ARCH%
set licenseroot=%origroot%dependencies\licenses

if not exist "%outputroot%" mkdir "%outputroot%"
if not exist "%outputroot%\bin" mkdir "%outputroot%\bin"
if not exist "%outputroot%\lib" mkdir "%outputroot%\lib"
if not exist "%outputroot%\include" mkdir "%outputroot%\include"
if not exist "%licenseroot%" mkdir "%licenseroot%"

echo ==============================
echo Building PDCurses
echo ==============================

cd "%srcroot%\pdcurses\wincon"
nmake -f Makefile.vc clean

if "%CONF%" == "debug" (
	nmake -f Makefile.vc DEBUG=Y WIDE=Y UTF8=Y pdcurses.lib
) else (
	nmake -f Makefile.vc WIDE=Y UTF8=Y pdcurses.lib
)

set PDCURSES_RESULT=%ERRORLEVEL%

if %PDCURSES_RESULT% == 0 (
	cd "%srcroot%\pdcurses"
	copy wincon\*.lib "%outputroot%\lib\"
	copy *.h "%outputroot%\include\"
	copy README.md "%licenseroot%\pdcurses.txt"
)

echo(
echo ==============================
echo Building zlib
echo ==============================

cd "%srcroot%\zlib"
nmake -f win32\Makefile.msc clean
nmake -f win32\Makefile.msc zdll.lib

set ZLIB_RESULT=%ERRORLEVEL%

if %ZLIB_RESULT% == 0 (
	cd "%srcroot%\zlib"
	copy *.dll "%outputroot%\bin\"
	:: The curl build expects the zdll.* files to be named zlib.*
	copy zdll.lib "%outputroot%\lib\zlib.lib"
	if "%CONF%" == "debug" (
		copy zdll.pdb "%outputroot%\lib\zlib.pbd"
	)
	copy zdll.exp "%outputroot%\lib\zlib.exp"
	copy *.h "%outputroot%\include\"
	copy README "%licenseroot%\zlib.txt"
)

echo(
echo ==============================
echo Building libpng
echo ==============================

cd "%srcroot%\libpng"
nmake -f scripts\makefile.vcwin32 clean
nmake -f scripts\makefile.vcwin32 libpng.lib

set LIBPNG_RESULT=%ERRORLEVEL%

if %LIBPNG_RESULT% == 0 (
	cd "%srcroot%\libpng"
	copy libpng.lib "%outputroot%\lib\"
	copy *.h "%outputroot%\include\"
	copy LICENSE "%licenseroot%\libpng.txt"
)

echo(
echo ==============================
echo Building c-ares
echo ==============================

cd "%srcroot%\c-ares"

nmake -f Makefile.msvc clean
nmake -f Makefile.msvc CFG=dll-%CONF% c-ares
set CARES_RESULT=%ERRORLEVEL%
cd "%srcroot%\c-ares"

:: Copy the necessary files to the output directory
if %CARES_RESULT% == 0 (
	copy include\*.h "%outputroot%\include\"
	
	copy "msvc\cares\dll-%CONF%\*.dll" "%outputroot%\bin\"
	copy "msvc\cares\dll-%CONF%\*.lib" "%outputroot%\lib\"
	copy "msvc\cares\dll-%CONF%\*.exp" "%outputroot%\lib\"
	copy LICENSE.md "%licenseroot%\c-ares.txt"
)

echo(
echo ==============================
echo Building libcurl
echo ==============================

cd "%srcroot%\curl\winbuild"

nmake -f Makefile.vc clean
if "%CONF%" == "debug" (
	nmake -f Makefile.vc mode=dll VC=15 WITH_DEVEL="%outputroot%" WITH_ZLIB=dll WITH_CARES=dll ENABLE_IDN=no ENABLE_SCHANNEL=yes GEN_PDB=no DEBUG=yes MACHINE=%ARCH%
) else (
	nmake -f Makefile.vc mode=dll VC=15 WITH_DEVEL="%outputroot%" WITH_ZLIB=dll WITH_CARES=dll ENABLE_IDN=no ENABLE_SCHANNEL=yes GEN_PDB=no DEBUG=no MACHINE=%ARCH%
)

set CURL_RESULT=%ERRORLEVEL%

if %CURL_RESULT% == 0 (
	cd "%srcroot%\curl\builds\libcurl-vc15-%ARCH%-%CONF%-dll-cares-dll-zlib-dll-ipv6-sspi-schannel"
	copy bin\*.dll "%outputroot%\bin\"
	copy lib\*.lib "%outputroot%\lib\"
	copy lib\*.exp "%outputroot%\lib\"
	copy lib\*.pdb "%outputroot%\lib\"
	if not exist %outputroot%\include\curl mkdir "%outputroot%\include\curl"
	copy include\curl\*.h "%outputroot%\include\curl\"
	cd "%srcroot%\curl"
	copy COPYING "%licenseroot%\curl.txt"
)

echo(
echo ==============================
echo Building regex
echo ==============================

cd "%srcroot%\regex"
if "%ARCH%" == "x86" (
	msbuild regex.sln /property:Configuration=%CONF% /property:Platform=Win32 /p:PlatformToolset=v141 /p:WindowsTargetPlatformVersion=10.0.17763.0
) else (
	msbuild regex.sln /property:Configuration=%CONF% /property:Platform=x64 /p:PlatformToolset=v141 /p:WindowsTargetPlatformVersion=10.0.17763.0
)

set REGEX_RESULT=%ERRORLEVEL%

if %REGEX_RESULT% == 0 (
	cd "%srcroot%\regex"
	if "%ARCH%" == "x86" (
		copy regex_Win32_%CONF%\regex.lib "%outputroot%\lib"
	) else (
		copy regex_x64_%CONF%\regex.lib "%outputroot%\lib"
	)
	copy regex.h "%outputroot%\include"
	copy license.txt "%licenseroot%\regex.txt"
)

echo(
echo ==============================
echo Building GLEW
echo ==============================

cd "%srcroot%\glew\build\vc12"
if "%ARCH%" == "x86" (
	msbuild glew.sln /property:Configuration=%CONF% /property:Platform=Win32 /p:PlatformToolset=v141 /p:WindowsTargetPlatformVersion=10.0.17763.0
) else (
	msbuild glew.sln /property:Configuration=%CONF% /property:Platform=x64 /p:PlatformToolset=v141 /p:WindowsTargetPlatformVersion=10.0.17763.0
)

set GLEW_RESULT=%ERRORLEVEL%

if %GLEW_RESULT% == 0 (
	cd "%srcroot%\glew"
	if "%ARCH%" == "x86" (
		copy lib\%CONF%\Win32\*.exp "%outputroot%\lib"
		copy lib\%CONF%\Win32\glew*s*.lib "%outputroot%\lib"
		copy bin\%CONF%\Win32\*.pdb "%outputroot%\lib"
	) else (
		copy lib\%CONF%\x64\*.exp "%outputroot%\lib"
		copy lib\%CONF%\x64\glew*s*.lib "%outputroot%\lib"
		copy bin\%CONF%\x64\*.pdb "%outputroot%\lib"
	)
	if not exist "%outputroot%\include\GL" mkdir "%outputroot%\include\GL"
	copy "include\GL\*.h" "%outputroot%\include\GL"
	copy LICENSE.txt "%licenseroot%\GLEW.txt"
)

echo(
echo ==============================
echo Building SDL2
echo ==============================

cd "%srcroot%\SDL2\VisualC"
if "%ARCH%" == "x86" (
	msbuild SDL.sln /property:Configuration=%CONF% /property:Platform=Win32 /p:PlatformToolset=v141 /p:WindowsTargetPlatformVersion=10.0.17763.0
) else (
	msbuild SDL.sln /property:Configuration=%CONF% /property:Platform=x64 /p:PlatformToolset=v141 /p:WindowsTargetPlatformVersion=10.0.17763.0
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
	if not exist "%outputroot%\include\SDL2" mkdir "%outputroot%\include\SDL2"
	copy "include\*.h" "%outputroot%\include\SDL2\"
	copy COPYING.txt "%licenseroot%\SDL2.txt"
)

echo(
echo ==============================
echo Copying glm
echo ==============================

cd "%srcroot%\glm"
robocopy /E /NP /NJH /NJS glm "%outputroot%\include\glm"
set GLM_RESULT=%ERRORLEVEL%
copy copying.txt "%licenseroot%\glm.txt"


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
if %ZLIB_RESULT% == 0 (
	echo zlib ................... SUCCESS!
) else (
	echo zlib ................... FAILED!
)
if %LIBPNG_RESULT% == 0 (
	echo libpng ................. SUCCESS!
) else (
	echo libpng ................. FAILED!
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
if %GLEW_RESULT% == 0 (
	echo GLEW ................... SUCCESS!
) else (
	echo GLEW ................... FAILED!
)
if %SDL2_RESULT% == 0 (
	echo SDL2 ................... SUCCESS!
) else (
	echo SDL2 ................... FAILED!
)
if /I %GLM_RESULT% LEQ 7 (
	echo GLM .................... SUCCESS!
) else (
	echo GLM .................... FAILED!
)

cd %origroot%
goto:eof
