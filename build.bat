@echo off
rem See 'readme.md' file

setlocal

set PLATFORM=%1
if "%PLATFORM%" == "" set PLATFORM=Win64
if "%PLATFORM%" neq "Win32" if "%PLATFORM%" neq "Win64" (
  echo Unknown plaform, use Win32 or Win64
  exit /B 1
)

if "%PROCESSOR_ARCHITECTURE%"=="x86" (
  set "PROGRAMFILES32=%ProgramFiles%"
  set "PROGRAMFILES64=%ProgramW6432%"
) else if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set "PROGRAMFILES32=%ProgramFiles(x86)%"
  set "PROGRAMFILES64=%ProgramFiles%"
) else (
  echo Unrecognized architecture %PROCESSOR_ARCHITECTURE%
  exit /B 1
)

rem C++Builder 13 Community Edition, then 11.
set "BDS=%PROGRAMFILES32%\Embarcadero\Studio\37.0"
if not exist "%BDS%\bin\rsvars.bat" set "BDS=%PROGRAMFILES32%\Embarcadero\Studio\22.0"
if not exist "%BDS%\bin\rsvars.bat" (
  echo Cannot find C++Builder. Install Community Edition or set BDS.
  exit /B 1
)
rem rsvars.bat clears PLATFORM.
set "WINSCP_PLATFORM=%PLATFORM%"
call "%BDS%\bin\rsvars.bat"
set "PLATFORM=%WINSCP_PLATFORM%"
if not defined FrameworkDir set "FrameworkDir=%WINDIR%\Microsoft.NET\Framework\v4.0.30319"
set "MSBUILD=%FrameworkDir%\MSBuild.exe"
if not exist "%MSBUILD%" (
  echo Cannot find MSBuild at %MSBUILD%
  exit /B 1
)

set WITH_DOTNET=1
if "%BUILD_TARGET%"=="" set BUILD_TARGET=Build
if "%BUILD_CONFIG%"=="" set BUILD_CONFIG=Release

set BUILDTOOLS=%~dp0\buildtools

if exist "%BUILDTOOLS%\tools\nasm.exe" (
  set "NASM=%BUILDTOOLS%\tools\nasm.exe"
) else if exist "%ProgramFiles%\NASM\nasm.exe" (
  set "NASM=%ProgramFiles%\NASM\nasm.exe"
) else (
  for /f "delims=" %%I in ('where nasm 2^>nul') do if not defined NASM set "NASM=%%I"
)
if not defined NASM (
  echo Cannot find nasm.exe. Install NASM or put it at buildtools\tools\nasm.exe
  exit /B 1
)
if "%PLATFORM%"=="Win32" if not exist "%BUILDTOOLS%\tools\objconv.exe" (
  echo Win32 build needs buildtools\tools\objconv.exe
  exit /B 1
)

cd libs
set INTERM_PATH=%~dp0\source
call buildlibs.bat %PLATFORM%
if errorlevel 1 (
  echo Error building libs
  exit /B 1
)
set INTERM_PATH=

cd ..\source
"%BDS%\bin\dcc64.exe" -? >"%TEMP%\winscp-dcc.txt" 2>&1
findstr /C:"does not support command line compiling" "%TEMP%\winscp-dcc.txt" >nul
if not errorlevel 1 goto USE_BDS

set BDS_BUILD_PROPERTIES=RELEASE_TYPE=%RELEASE_TYPE%;CONFIG=%BUILD_CONFIG%;INTERM_PATH=.;FINAL_PATH=.
"%MSBUILD%" WinSCP.groupproj /t:%BUILD_TARGET% /p:%BDS_BUILD_PROPERTIES%;Platform=%PLATFORM%
if errorlevel 1 exit /B 1
if "%PLATFORM%" == "Win32" "%MSBUILD%" DragExt.cbproj /t:%BUILD_TARGET% /p:%BDS_BUILD_PROPERTIES%;Platform=Win64
if errorlevel 1 exit /B 1
goto AFTER_CPP

:USE_BDS
echo Community Edition has no command-line Delphi compiler. Building with the IDE.
set INTERM_PATH=.
set FINAL_PATH=.
set CONFIG=%BUILD_CONFIG%
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-ide.ps1" -Source "%CD%" -Platform "%PLATFORM%" -Bds "%BDS%\bin\bds.exe"
if errorlevel 1 exit /B 1

:AFTER_CPP

if "%WITH_DOTNET%"=="0" goto SKIP_DOTNET
dotnet --version >nul 2>&1
if errorlevel 1 (
  echo Skipping WinSCPnet. Install a .NET SDK to build the assembly.
  goto SKIP_DOTNET
)
cd ..\dotnet
set DOTNET_BUILD_PROPERTIES=INTERM_PATH=.;FINAL_PATH=.
dotnet restore WinSCPnet.csproj -p:%DOTNET_BUILD_PROPERTIES%
dotnet build WinSCPnet.csproj -c %BUILD_CONFIG% -p:%DOTNET_BUILD_PROPERTIES%
:SKIP_DOTNET
