@echo off
setlocal

echo ============================================================
echo [PreBuild] Auto-build zlib
echo ============================================================

rem --- Define paths relative to this script (which lives in repo root) ---
set "ROOT=%~dp0"
set "SLN=%ROOT%external\zlib\contrib\vstudio\vc17\zlibvc.sln"
set "OUTDIR=%ROOT%external\zlib\contrib\vstudio\vc17\x64\ZlibStatRelease"
set "BUILT_LIB=%OUTDIR%\zlibstat.lib"
set "TARGET_LIB=%ROOT%mgs\3rdparty\zlib\zlib.lib"

echo [PreBuild] Checking for zlib (Release build)...
echo [PreBuild] Target library: "%TARGET_LIB%"

rem --- If final lib already exists, skip build ---
if exist "%TARGET_LIB%" (
    echo [PreBuild] Found existing library: "%TARGET_LIB%"
    exit /b 0
)

echo [PreBuild] zlib.lib not found — building static Release library...

rem --- Locate MSBuild using vswhere ---
set "MSBUILD_EXE="
for /f "usebackq tokens=*" %%I in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do set "MSBUILD_EXE=%%I"

if "%MSBUILD_EXE%"=="" (
    echo [PreBuild] ERROR: Could not locate MSBuild.exe via vswhere.
    exit /b 1
)

echo [PreBuild] Using MSBuild: "%MSBUILD_EXE%"
"%MSBUILD_EXE%" "%SLN%" /p:Configuration=Release /p:Platform=x64 /t:Build /nologo /v:minimal

if errorlevel 1 (
    echo [PreBuild] ERROR: zlib build failed.
    exit /b 1
)

if not exist "%BUILT_LIB%" (
    echo [PreBuild] ERROR: Build completed, but library not found at "%BUILT_LIB%"
    exit /b 1
)

echo [PreBuild] Successfully built zlib: "%BUILT_LIB%"
echo [PreBuild] Copying to "%TARGET_LIB%"...

rem --- Create destination folder if missing ---
for %%F in ("%TARGET_LIB%") do if not exist "%%~dpF" mkdir "%%~dpF"

copy /Y "%BUILT_LIB%" "%TARGET_LIB%" >nul
if errorlevel 1 (
    echo [PreBuild] ERROR: Failed to copy built library to target path.
    exit /b 1
)

echo [PreBuild] Copied successfully: "%TARGET_LIB%"
exit /b 0
