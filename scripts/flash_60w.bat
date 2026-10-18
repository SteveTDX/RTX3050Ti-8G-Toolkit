@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem flash_60w.bat - restore the original vBIOS
rem
rem Default : newest file in backups\ (the real factory image of THIS machine)
rem Fallback: roms\RTX3050Ti_Laptop_94.07.3a.00.0e.rom (author reference dump)
rem
rem   flash_60w.bat               auto select
rem   flash_60w.bat --reference   force the bundled reference ROM
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

set "REFROM=%ROMS%\RTX3050Ti_Laptop_94.07.3a.00.0e.rom"
set "CLOG=%LOGS%\flash_60w.log"

call "%LIB%" require_admin "%~f0" %1
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" probe
call "%LIB%" title M0093

if not exist "%TOOLS%\nvflashb.exe" (
    call "%LIB%" err M0094
    call "%LIB%" msg M0095
    echo.
    pause
    exit /b 1
)

set "USE_BACKUP=0"
set "ROM="
if /i "%~1"=="--reference" goto :use_ref
for /f "delims=" %%F in ('dir /b /o-d "%BACKUPS%\*.rom" 2^>nul') do (
    if not defined ROM set "ROM=%BACKUPS%\%%F"
)
if defined ROM set "USE_BACKUP=1"
:use_ref
if not defined ROM set "ROM=%REFROM%"

if not exist "!ROM!" (
    call "%LIB%" err M0096
    call "%LIB%" msg M0097
    call "%LIB%" msg M0098
    echo.
    pause
    exit /b 1
)

if "%USE_BACKUP%"=="1" (
    call "%LIB%" msg M0099
    call "%LIB%" msg M0100
) else (
    call "%LIB%" msg M0101
    call "%LIB%" msg M0102
    echo.
    call "%LIB%" warn M0103
    call "%LIB%" msg M0104
)

call "%LIB%" msg M0105
call "%LIB%" msg M0106
call "%LIB%" msg M0107
echo.
set "ANS="
call "%LIB%" msgs M0108
set /p ANS=!MSGTXT!
if not "!ANS!"=="" (
    call "%LIB%" info M0109
    goto :the_end
)

echo.
call "%LIB%" msg M0110
call "%LIB%" msg M0111
call "%LIB%" flash_rom "!ROM!" "%CLOG%"
echo.

if "%FLASH_RC%"=="0" (
    call "%LIB%" ok M0112
    call "%LIB%" msg M0113
) else (
    call "%LIB%" err M0114
    if not "%FLASH_HINT%"=="" echo   %FLASH_HINT%
    echo.
    call "%LIB%" msg M0115
    call "%LIB%" msg M0116
    call "%LIB%" msg M0117
    call "%LIB%" msg M0118
    call "%LIB%" msg M0119
)
call "%LIB%" log "%LOGS%\flash_history.log" "flash_60w rc=%FLASH_RC% state=%FLASH_STATE% rom=!ROM!"

:the_end
echo.
pause
