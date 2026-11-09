@echo off
setlocal
rem Baut ComicShooter.apk (Debug-Signatur).
rem Aufruf:  export_apk.bat "C:\Pfad\zu\Godot.exe"
set GODOT=%~1
if "%GODOT%"=="" set GODOT=godot
echo Benutze: %GODOT%
"%GODOT%" --headless --path "%~dp0project" --export-debug "Android" "%~dp0ComicShooter.apk"
if errorlevel 1 (
  echo.
  echo FEHLER: Export fehlgeschlagen.
  echo Sind JDK und Android SDK in den Editor-Einstellungen gesetzt?
  pause
  exit /b 1
)
echo.
echo Fertig: ComicShooter.apk
pause
