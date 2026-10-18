@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
rem ============================================================================
rem preflight.bat - adaptive environment pre-check
rem
rem exit code 0 = ready, 2 = usable with warnings, 1 = blocked
rem flags: --quiet  (no pause, minimal output)
rem ============================================================================
cd /d "%~dp0"
set "LIB=%~dp0lib\common.bat"
call "%LIB%" init

set "QUIET=0"
if /i "%~1"=="--quiet" set "QUIET=1"
if /i "%~1"=="--nopause" set "QUIET=2"

set "FAILS=0"
set "WARNS=0"
set "REPORT=%LOGS%\preflight.txt"

call "%LIB%" probe
if not "%PROBE_OK%"=="1" goto :degraded

rem ---------------------------------------------------------------- OS / arch
set "OS_NAME=%OS_FAMILY%"
if not "%OS_DISPLAY%"=="" set "OS_NAME=%OS_FAMILY% %OS_DISPLAY%"
set "OS_TXT=%OS_NAME% build %OS_BUILD%"
set "OS_ST=OK"
if %OS_BUILD% LSS 17763 (
    set "OS_ST=FAIL"
    set /a FAILS+=1
) else if %OS_BUILD% LSS 22000 (
    set "OS_ST=OK"
) else (
    set "OS_ST=OK"
)

set "ARCH_ST=OK"
if /i not "%OS_ARCH%"=="AMD64" set "ARCH_ST=FAIL"
if /i "%OS_ARCH%"=="ARM64" set "ARCH_ST=FAIL"
if "%ARCH_ST%"=="FAIL" set /a FAILS+=1

set "PS_ST=OK"
for /f "tokens=1 delims=." %%p in ("%PS_VERSION%") do set "PS_MAJOR=%%p"
if not defined PS_MAJOR set "PS_MAJOR=0"
if %PS_MAJOR% LSS 5 set "PS_ST=FAIL"
if "%PS_ST%"=="FAIL" set /a FAILS+=1

rem ---------------------------------------------------------------- GPU
set "GPU_ST=OK"
if not "%GPU_PRESENT%"=="1" set "GPU_ST=FAIL"
if "%GPU_ST%"=="FAIL" set /a FAILS+=1

call "%LIB%" check_model
set "MODEL_ST=OK"
if not "%MODEL_OK%"=="0" set "MODEL_ST=WARN"
if "%MODEL_ST%"=="WARN" set /a WARNS+=1

set "DEV_ST=OK"
if /i not "%GPU_DEV%"=="25A0" set "DEV_ST=WARN"
if "%DEV_ST%"=="WARN" set /a WARNS+=1

set "STATUS_ST=OK"
if /i not "%GPU_STATUS%"=="OK" set "STATUS_ST=WARN"
if "%GPU_STATUS%"=="" set "STATUS_ST=WARN"
if "%STATUS_ST%"=="WARN" set /a WARNS+=1

set "VRAM_ST=OK"
set "VRAM_TXT=%GPU_VRAM_MB% MiB"
if "%GPU_VRAM_MB%"=="0" (
    call "%LIB%" msgs M0202
    set "VRAM_TXT=!MSGTXT!"
    set "VRAM_ST=WARN"
)
if "%GPU_VRAM_MB%"=="8192" call "%LIB%" msgs M0203
if "%GPU_VRAM_MB%"=="8192" set "VRAM_TXT=!MSGTXT!"
if "%GPU_VRAM_MB%"=="4096" call "%LIB%" msgs M0204
if "%GPU_VRAM_MB%"=="4096" set "VRAM_TXT=!MSGTXT!"
if "%VRAM_ST%"=="WARN" set /a WARNS+=1

set "DRV_ST=OK"
if "%NVIDIA_DRIVER%"=="" set "DRV_ST=WARN"
if "%DRV_ST%"=="WARN" set /a WARNS+=1

set "SMI_ST=OK"
if "%SMI_PATH%"=="" set "SMI_ST=FAIL"
if "%SMI_ST%"=="FAIL" set /a FAILS+=1

rem ---------------------------------------------------------------- power
call "%LIB%" power_csv
call "%LIB%" msgs M0205
set "PWR_TXT=!MSGTXT!"
if defined PWR_DEF call "%LIB%" msgs M0206
if defined PWR_DEF set "PWR_TXT=!MSGTXT!"

rem ---------------------------------------------------------------- files
call "%LIB%" find_smi

set "HASH_NVFLASH="
if exist "%TOOLS%\SHA256SUMS.txt" (
    for /f "tokens=1 delims= " %%a in ('findstr /i /c:"nvflashb.exe" "%TOOLS%\SHA256SUMS.txt" 2^>nul') do (
        if not defined HASH_NVFLASH set "HASH_NVFLASH=%%a"
    )
)
set "TOOL_ST=OK"
call "%LIB%" msgs M0207
set "TOOL_TXT=!MSGTXT!"
if not exist "%TOOLS%\nvflashb.exe" (
    set "TOOL_ST=FAIL"
    call "%LIB%" msgs M0208
    set "TOOL_TXT=!MSGTXT!"
) else if defined HASH_NVFLASH (
    call "%LIB%" sha256 "%TOOLS%\nvflashb.exe"
    if /i not "!HASH!"=="!HASH_NVFLASH!" (
        set "TOOL_ST=FAIL"
        call "%LIB%" msgs M0209
        set "TOOL_TXT=!MSGTXT!"
    )
)
if "%TOOL_ST%"=="FAIL" set /a FAILS+=1

set "ROM60_ST=OK"
call "%LIB%" msgs M0210
set "ROM60_TXT=!MSGTXT!"
if not exist "%ROMS%\RTX3050Ti_Laptop_94.07.3a.00.0e.rom" (
    set "ROM60_ST=WARN"
    call "%LIB%" msgs M0211
    set "ROM60_TXT=!MSGTXT!"
)
if "%ROM60_ST%"=="WARN" set /a WARNS+=1

set "ROM80_ST=OK"
call "%LIB%" msgs M0212
set "ROM80_TXT=!MSGTXT!"
if not exist "%ROMS%\HP.RTX3050TiMobile.4096.210618.rom" (
    set "ROM80_ST=WARN"
    call "%LIB%" msgs M0213
    set "ROM80_TXT=!MSGTXT!"
)
if "%ROM80_ST%"=="WARN" set /a WARNS+=1

set "DISK_ST=OK"
if %DISK_FREE_MB% LSS 200 set "DISK_ST=WARN"
if "%DISK_ST%"=="WARN" set /a WARNS+=1

rem ---------------------------------------------------------------- profile
call "%LIB%" machine_profile
call "%LIB%" msgs M0214
set "PROFILE_ST_TXT=!MSGTXT!"
if "%PROFILE_STATE%"=="same" call "%LIB%" msgs M0215
if "%PROFILE_STATE%"=="same" set "PROFILE_ST_TXT=!MSGTXT!"
if "%PROFILE_STATE%"=="changed" (
    call "%LIB%" msgs M0216
    set "PROFILE_ST_TXT=!MSGTXT!"
    set /a WARNS+=1
)

rem ---------------------------------------------------------------- output
if "%QUIET%"=="1" goto :summary

call "%LIB%" title M0217

call "%LIB%" msg M0218
call "%LIB%" msg M0219
echo   PowerShell    : !PS_VERSION!  [!PS_ST!]
call "%LIB%" msg M0220
echo.
call "%LIB%" msg M0221
call "%LIB%" msg M0222
call "%LIB%" msg M0223
call "%LIB%" msg M0224
call "%LIB%" msg M0225
echo   nvidia-smi    : !SMI_PATH!  [!SMI_ST!]
call "%LIB%" msg M0226
echo.
call "%LIB%" msg M0227
echo   nvflashb.exe  : !TOOL_TXT!  [!TOOL_ST!]
call "%LIB%" msg M0228
echo   80W OEM ROM   : !ROM80_TXT!  [!ROM80_ST!]
call "%LIB%" msg M0229
echo.
call "%LIB%" msg M0230
call "%LIB%" msg M0231
if "%PROFILE_STATE%"=="changed" (
    call "%LIB%" msg M0232
)

rem ------------------------------------------------------- startup task path
rem The logon task hard-codes an absolute path. After moving the folder, or
rem after swapping the mainboard / CPU and restoring a disk image to a new
rem machine, that path can point at a directory that no longer exists.
echo.
call "%LIB%" msg M0079
if "%TASK_EXISTS%"=="1" (
    set "TASK_OK=0"
    echo !TASK_CMD! | findstr /i /c:"!ROOT!" >nul && set "TASK_OK=1"
    if "!TASK_OK!"=="1" (
        call "%LIB%" msg M0376
        call "%LIB%" msg M0081
    ) else (
        set /a WARNS+=1
        call "%LIB%" warn M0377
        call "%LIB%" msg M0021
    )
) else (
    call "%LIB%" msg M0378
)
echo.

:summary
> "%REPORT%" echo RTX3050Ti-8G-Toolkit preflight report
>>"%REPORT%" echo time=%DATE% %TIME%
>>"%REPORT%" echo os=%OS_TXT% state=%OS_ST%
>>"%REPORT%" echo arch=%OS_ARCH% state=%ARCH_ST%
>>"%REPORT%" echo ps=%PS_VERSION% state=%PS_ST%
>>"%REPORT%" echo gpu=%GPU_NAME% state=%GPU_ST%
>>"%REPORT%" echo pci=VEN_%GPU_VEN%_DEV_%GPU_DEV%_SUBSYS_%GPU_SUBSYS% state=%DEV_ST%
>>"%REPORT%" echo vram_mb=%GPU_VRAM_MB% state=%VRAM_ST%
>>"%REPORT%" echo driver=%NVIDIA_DRIVER% state=%DRV_ST%
>>"%REPORT%" echo smi=%SMI_PATH% state=%SMI_ST%
>>"%REPORT%" echo power=%PWR_TXT%
>>"%REPORT%" echo tool=%TOOL_ST%
>>"%REPORT%" echo rom60=%ROM60_ST% rom80=%ROM80_ST%
>>"%REPORT%" echo profile=%PROFILE_STATE%
>>"%REPORT%" echo fails=%FAILS% warns=%WARNS%

rem QUIET: 0 = interactive, 1 = silent (--quiet), 2 = verbose without pause
if %FAILS% GTR 0 (
    if not "%QUIET%"=="1" (
        call "%LIB%" err M0233
        call "%LIB%" msg M0234
        echo.
    )
    if "%QUIET%"=="0" pause
    exit /b 1
)
if %WARNS% GTR 0 (
    if not "%QUIET%"=="1" (
        call "%LIB%" warn M0235
        call "%LIB%" msg M0236
        echo.
    )
    if "%QUIET%"=="0" pause
    exit /b 2
)
if not "%QUIET%"=="1" (
    call "%LIB%" ok M0237
    call "%LIB%" msg M0238
    echo.
)
if "%QUIET%"=="0" pause
exit /b 0

rem ---------------------------------------------------------------- degraded
:degraded
call "%LIB%" find_smi
call "%LIB%" check_gpu
set "GPU_PRESENT=0"
if "%GPU_FOUND%"=="0" set "GPU_PRESENT=1"
set "GPU_NAME=%GPU_NAME%"
set "GPU_VRAM_MB=0"
set "GPU_DEV="
call "%LIB%" msgs M0239
set "OS_TXT=!MSGTXT!"
set "ARCH_TXT=%PROCESSOR_ARCHITECTURE%"
call "%LIB%" title M0240
call "%LIB%" warn M0241
call "%LIB%" msg M0242
cmd /c ver
call "%LIB%" msg M0243
echo   nvidia-smi    : !SMI_PATH!
echo.
call "%LIB%" check_model
if not "%MODEL_OK%"=="0" (
    call "%LIB%" err M0244
    if "%QUIET%"=="0" pause
    exit /b 1
)
call "%LIB%" power_csv
call "%LIB%" msg M0245
echo.
call "%LIB%" warn M0246
if "%QUIET%"=="0" pause
exit /b 2
