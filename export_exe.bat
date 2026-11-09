@echo off
setlocal
rem Baut ComicShooter.exe mit Godot 4.7.2.
rem Aufruf:  export_exe.bat "C:\Pfad\zu\Godot_v4.7.2-stable_win64.exe"
set GODOT=%~1
if "%GODOT%"=="" set GODOT=godot
echo Benutze: %GODOT%
"%GODOT%" --headless --path "%~dp0project" --export-release "Windows Desktop" "%~dp0ComicShooter.exe"
if errorlevel 1 (
  echo.
  echo FEHLER: Export fehlgeschlagen.
  echo Sind die Export-Templates fuer Godot 4.7.2 installiert?
  echo Editor -^> Manage Export Templates -^> Download
  pause
  exit /b 1
)
echo.
echo Fertig: ComicShooter.exe
pause
