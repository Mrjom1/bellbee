@echo off
rem Runs BellBee with a local Godot 4.5.1 binary instead of an exported build.
rem Looks in Tools\Godot_4.5.1 first, then reuses the copy in the sibling Territory project.
setlocal
set "ROOT=%~dp0"
set "GODOT_DIR=%ROOT%Tools\Godot_4.5.1"
if not exist "%GODOT_DIR%\Godot_v4.5.1-stable_win64.exe" set "GODOT_DIR=%ROOT%..\Territory\Tools\Godot_4.5.1"
set "GODOT=%GODOT_DIR%\Godot_v4.5.1-stable_win64.exe"
set "GODOT_CONSOLE=%GODOT_DIR%\Godot_v4.5.1-stable_win64_console.exe"

if not exist "%GODOT%" (
    echo Godot 4.5.1 not found in Tools\Godot_4.5.1 or ..\Territory\Tools\Godot_4.5.1
    pause
    exit /b 1
)

rem Import first so new scripts and classes are registered before the game starts.
"%GODOT_CONSOLE%" --headless --path "%ROOT%Game" --import >nul 2>&1
start "" "%GODOT%" --path "%ROOT%Game"
