@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem verify.bat - integrity check: text encoding, tool hash, firmware hashes
rem exit code 0 = pass, 2 = warnings, 1 = failure
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

set "NOPAUSE=0"
if /i "%~1"=="--quiet" set "NOPAUSE=1"
if /i "%~1"=="--pack-mode" set "NOPAUSE=1"

call "%LIB%" title M0325

set "FAILS=0"
set "WARNS=0"
set "TXT=%LOGS%\check_text.txt"

if not exist "%ROOT%\scripts\lib\check_text.ps1" (
    call "%LIB%" err M0326
    set /a FAILS+=1
    goto :hash
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\lib\check_text.ps1" -Root "%ROOT%" -OutFile "%TXT%" >nul 2>&1
if not exist "%TXT%" (
    call "%LIB%" err M0327
    set /a FAILS+=1
    goto :hash
)

set "TEXT_RESULT="
for /f "usebackq tokens=1,* delims==" %%a in ("%TXT%") do (
    if /i "%%a"=="RESULT" set "TEXT_RESULT=%%b"
    if /i "%%a"=="BAT_COUNT" set "BAT_COUNT=%%b"
    if /i "%%a"=="BAD" (
        echo   [WARN] %%b
        set /a WARNS+=1
    )
)
if "%TEXT_RESULT%"=="ok" (
    call "%LIB%" ok M0328
) else (
    call "%LIB%" err M0329
    set /a FAILS+=1
)

:hash
echo.
call "%LIB%" msg M0330
set "H1="
if exist "%TOOLS%\SHA256SUMS.txt" (
    for /f "tokens=1 delims= " %%a in ('findstr /i /c:"nvflashb.exe" "%TOOLS%\SHA256SUMS.txt" 2^>nul') do (
        if not defined H1 set "H1=%%a"
    )
)
if not exist "%TOOLS%\nvflashb.exe" (
    call "%LIB%" err M0331
    set /a FAILS+=1
) else if defined H1 (
    call "%LIB%" sha256 "%TOOLS%\nvflashb.exe"
    if /i "!HASH!"=="!H1!" (
        call "%LIB%" ok M0332
    ) else (
        call "%LIB%" err M0333
        call "%LIB%" msg M0334
        call "%LIB%" msg M0335
        set /a FAILS+=1
    )
) else (
    call "%LIB%" warn M0336
    set /a WARNS+=1
)

if not exist "%ROMS%\SHA256SUMS.txt" (
    call "%LIB%" warn M0337
    set /a WARNS+=1
    goto :files
)

for /f "tokens=1,* delims= " %%a in ('type "%ROMS%\SHA256SUMS.txt"') do (
    set "FH=%%a"
    set "FN=%%b"
    if exist "%ROMS%\!FN!" (
        call "%LIB%" sha256 "%ROMS%\!FN!"
        if /i "!HASH!"=="!FH!" (
            call "%LIB%" ok M0338
        ) else (
            call "%LIB%" warn M0339
            set /a WARNS+=1
        )
    ) else (
        call "%LIB%" warn M0340
        set /a WARNS+=1
    )
)

:files
echo.
call "%LIB%" msg M0341
for %%F in (
    "menu.bat"
    "bootstrap.bat"
    "pack_release.bat"
    "scripts\preflight.bat"
    "scripts\status.bat"
    "scripts\set_powerlimit.bat"
    "scripts\flash_80w.bat"
    "scripts\flash_60w.bat"
    "scripts\backup_vbios.bat"
    "scripts\restore_backup.bat"
    "setup\install_startup.bat"
    "setup\remove_startup.bat"
    "scripts\lib\common.bat"
    "scripts\lib\probe.ps1"
    "lang\zh-CN.txt"
) do (
    if exist "%ROOT%\%%~F" (
        echo   [OK] %%~F
    ) else (
        call "%LIB%" err M0342 "%%~F"
        set /a FAILS+=1
    )
)

echo.
call "%LIB%" log "%LOGS%\verify.log" "verify fails=!FAILS! warns=!WARNS!"
if %FAILS% GTR 0 (
    call "%LIB%" err M0343
    echo.
    if "%NOPAUSE%"=="0" pause
    exit /b 1
)
if %WARNS% GTR 0 (
    call "%LIB%" warn M0344
    echo.
    if "%NOPAUSE%"=="0" pause
    exit /b 2
)
call "%LIB%" ok M0345
echo.
if "%NOPAUSE%"=="0" pause
exit /b 0
