@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem restore_backup.bat - flash a previously saved backup back onto the card
rem
rem   restore_backup.bat            choose from list
rem   restore_backup.bat --latest   use newest backup
rem   restore_backup.bat 2          use entry #2 of the newest-first list
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

call "%LIB%" require_admin "%~f0" %1
if errorlevel 1 exit /b
call "%LIB%" is_admin
call "%LIB%" probe
call "%LIB%" title M0247

if not exist "%TOOLS%\nvflashb.exe" (
    call "%LIB%" err M0248
    echo.
    pause
    exit /b 1
)

set "COUNT=0"
for /f "delims=" %%F in ('dir /b /o-d "%BACKUPS%\*.rom" 2^>nul') do (
    set /a COUNT+=1
    set "B!COUNT!=%%F"
)

if "%COUNT%"=="0" (
    call "%LIB%" err M0249
    call "%LIB%" msg M0250
    echo.
    pause
    exit /b 1
)

call "%LIB%" msg M0251
for /l %%I in (1,1,!COUNT!) do (
    set "FN=!B%%I!"
    for %%A in ("%BACKUPS%\!FN!") do (
        call "%LIB%" msg M0252 "%%I" "!FN!" "%%~zA" "%%~tA"
    )
)
echo.

if /i "%~1"=="--latest" (
    set "SEL=1"
) else if "%~1"=="" (
    call "%LIB%" msgs M0253
    set /p SEL=!MSGTXT!
    if not defined SEL set "SEL=1"
) else (
    set "SEL=%~1"
)

set "NONNUM="
for /f "delims=0123456789" %%a in ("!SEL!") do set "NONNUM=%%a"
if defined NONNUM (
    call "%LIB%" err M0254
    goto :fail
)
if !SEL! LSS 1 (
    call "%LIB%" err M0255
    goto :fail
)
if !SEL! GTR !COUNT! (
    call "%LIB%" err M0256
    goto :fail
)

set "PICK=!B%SEL%!"
set "ROM=%BACKUPS%\!PICK!"
if not exist "!ROM!" (
    call "%LIB%" err M0257
    goto :fail
)

echo.
call "%LIB%" msg M0258
call "%LIB%" msg M0259
call "%LIB%" msg M0260
echo.
set "ANS="
call "%LIB%" msgs M0261
set /p ANS=!MSGTXT!
if /i not "!ANS!"=="YES" (
    call "%LIB%" info M0262
    goto :the_end
)

call "%LIB%" flash_rom "!ROM!" "%LOGS%\restore_backup.log"
echo.
if "%FLASH_RC%"=="0" (
    call "%LIB%" ok M0263
) else (
    call "%LIB%" err M0264
    echo   %FLASH_HINT%
    call "%LIB%" msg M0265
    call "%LIB%" msg M0266
)
call "%LIB%" log "%LOGS%\flash_history.log" "restore %PICK% rc=%FLASH_RC% state=%FLASH_STATE%"
goto :the_end

:fail
echo.
pause
exit /b 1

:the_end
echo.
pause
