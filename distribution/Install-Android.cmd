@echo off
setlocal
cd /d "%~dp0"
set "APK=%~dp0gtav-mobile-android-preview.apk"
if not exist "%APK%" (
  echo Extract the entire download first. The APK must be beside this installer.
  pause
  exit /b 1
)
set "ADB=adb"
if exist "%~dp0platform-tools\adb.exe" (
  set "ADB=%~dp0platform-tools\adb.exe"
) else (
  where adb >nul 2>nul
  if errorlevel 1 (
    echo Download Android SDK Platform-Tools for Windows from:
    echo https://developer.android.com/tools/releases/platform-tools
    echo Extract its platform-tools folder beside this script, then run this again.
    pause
    exit /b 1
  )
)
echo Connect one Android phone by USB. Enable USB debugging and approve the prompt on the phone.
"%ADB%" -d get-state >nul
if errorlevel 1 (
  echo No single authorized USB phone found. Unlock it, approve USB debugging, and connect only one phone.
  pause
  exit /b 1
)
"%ADB%" -d install -r "%APK%"
if errorlevel 1 (
  echo Installation failed. Review the adb error above.
  pause
  exit /b 1
)
echo Installed GTAV Mobile. Open it on your phone and import your own compatible game ZIP.
echo This is an experimental runtime; game files are not included.
pause
