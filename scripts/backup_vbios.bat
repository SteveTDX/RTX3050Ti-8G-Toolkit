@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem backup_vbios.bat - save the vBIOS currently on the card to backups\
rem Always run this before flashing anything, especially after changing
rem motherboard / CPU / laptop model.
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" require_admin "%~f0"
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" probe
call "%LIB%" title M0067

if not "%GPU_PRESENT%"=="1" (
    call "%LIB%" err M0068
    call "%LIB%" msg M0069
    echo.
    pause
    exit /b 1
)

call "%LIB%" msg M0070
call "%LIB%" msg M0071
call "%LIB%" msg M0072
call "%LIB%" machine_profile
if "%PROFILE_STATE%"=="changed" (
    call "%LIB%" warn M0073
)
echo.

call "%LIB%" backup_vbios
if not "%BACKUP_OK%"=="0" (
    echo.
    pause
    exit /b 1
)

call "%LIB%" sha256 "%BACKUP_FILE%"
set "BHASH=%HASH%"
for %%A in ("%BACKUP_FILE%") do set "BSZ=%%~zA"
>>"%BACKUPS%\index.txt" echo %DATE% %TIME%^|%BACKUP_FILE%^|%BSZ%^|%BHASH%^|VEN_%GPU_VEN%_DEV_%GPU_DEV%_SUBSYS_%GPU_SUBSYS%

call "%LIB%" ok M0074
call "%LIB%" msg M0075
call "%LIB%" msg M0076
echo   SHA256        : !BHASH!
echo.
call "%LIB%" msg M0077
call "%LIB%" msg M0078
echo.
pause
