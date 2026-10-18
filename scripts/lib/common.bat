@echo off
rem NOTE: no chcp here. The console code page is already 65001, set once by the
rem entry script. Running chcp on every call costs a process spawn per message.
rem ============================================================================
rem common.bat - shared command dispatcher for RTX3050Ti-8G-Toolkit
rem
rem usage: call "%~dp0lib\common.bat" <command> ["arg1"] ["arg2"]
rem
rem This file must NOT use setlocal/endlocal: variables set here have to
rem survive the call. cmd.exe cannot call a label in another file, so every
rem entry point is a command word dispatched by the block below.
rem ============================================================================

if "%~1"=="" goto :eof

if /i "%~1"=="init"            goto :c_init
if /i "%~1"=="title"           goto :c_title
if /i "%~1"=="ok"              goto :c_ok
if /i "%~1"=="warn"            goto :c_warn
if /i "%~1"=="err"             goto :c_err
if /i "%~1"=="info"            goto :c_info
if /i "%~1"=="msg"             goto :c_msg
if /i "%~1"=="msgs"            goto :c_msgs
if /i "%~1"=="die"             goto :c_die
if /i "%~1"=="probe"           goto :c_probe
if /i "%~1"=="find_smi"        goto :c_find_smi
if /i "%~1"=="check_gpu"       goto :c_check_gpu
if /i "%~1"=="check_model"     goto :c_check_model
if /i "%~1"=="require_admin"   goto :c_require_admin
if /i "%~1"=="is_admin"        goto :c_is_admin
if /i "%~1"=="sha256"          goto :c_sha256
if /i "%~1"=="check_file"      goto :c_check_file
if /i "%~1"=="check_files"     goto :c_check_files
if /i "%~1"=="power_csv"       goto :c_power_csv
if /i "%~1"=="is_uint"         goto :c_is_uint
if /i "%~1"=="log"             goto :c_log
if /i "%~1"=="timestamp"       goto :c_timestamp
if /i "%~1"=="trim"            goto :c_trim
if /i "%~1"=="backup_vbios"    goto :c_backup_vbios
if /i "%~1"=="flash_rom"       goto :c_flash_rom
if /i "%~1"=="classify_flash"  goto :c_classify_flash
if /i "%~1"=="machine_profile" goto :c_machine_profile
if /i "%~1"=="version"         goto :c_version
goto :eof

rem ------------------------------------------------------------------ paths
:c_init
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "TOOLS=%ROOT%\tools"
set "ROMS=%ROOT%\roms"
set "CONFIG=%ROOT%\config"
set "LOGS=%ROOT%\logs"
set "BACKUPS=%ROOT%\backups"
set "DIST=%ROOT%\dist"
for %%D in ("%LOGS%" "%CONFIG%" "%BACKUPS%") do if not exist "%%~D" mkdir "%%~D" >nul 2>&1
if exist "%ROOT%\VERSION" set /p VER=<"%ROOT%\VERSION"
if not defined VER set "VER=0.0.0"
call :load_msgs
goto :eof

rem ---- language table ---------------------------------------------------
rem Loaded once per process into MSG_M0001..MSG_M0378. A per-message lookup
rem would either scan the whole file (~250 ms) or spawn findstr (~225 ms),
rem and a single screen prints 20+ messages.
rem
rem The table keeps placeholders as ^!VAR^! on purpose: the caret survives the
rem for-variable substitution below, so MSG_M0030 really holds !OS_FAMILY!.
rem See :c_lookup for the pass that turns it into a value.
:load_msgs
if defined MSG_TABLE_OK goto :eof
set "MSG_TABLE_OK=1"
if not exist "%ROOT%\lang\zh-CN.txt" goto :eof
for /f "usebackq tokens=1,* delims=|" %%a in ("%ROOT%\lang\zh-CN.txt") do set "MSG_%%a=%%b"
goto :eof

rem ----------------------------------------------------------------- output
rem All UI strings live in lang\<lang>.txt as "ID|text". Batch sources stay
rem pure ASCII: cmd.exe loses file pointer sync when reading UTF-8 batch
rem files after chcp 65001, which randomly drops the first characters of a
rem line. Keeping .bat ASCII makes behaviour identical on every Windows build.
:c_msgs
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
exit /b 0

:c_lookup
set "MSGTXT="
if not defined MSG_TABLE_OK call :load_msgs
if defined MSG_%~1 set "MSGTXT=!MSG_%~1!"
if not defined MSGTXT set "MSGTXT=[%~1]"
if not "%~2"=="" set "MSGTXT=!MSGTXT:{1}=%~2!"
if not "%~3"=="" set "MSGTXT=!MSGTXT:{2}=%~3!"
if not "%~4"=="" set "MSGTXT=!MSGTXT:{3}=%~4!"
if not "%~5"=="" set "MSGTXT=!MSGTXT:{4}=%~5!"
if not "%~6"=="" set "MSGTXT=!MSGTXT:{5}=%~6!"
if not "%~7"=="" set "MSGTXT=!MSGTXT:{6}=%~7!"
rem Placeholders expand only when the text is fed back through a for variable:
rem that substitution happens before the delayed-expansion pass, so the pass
rem still sees !OS_FAMILY!. Copying with set "X=!T!" would be one pass too late.
if defined MSGTXT for /f "delims=" %%x in ("!MSGTXT!") do set "MSGTXT=%%x"
goto :eof

rem print helpers - call echo is required: the %%VAR%% form performs the
rem second expansion pass that turns !PLACEHOLDER! into the live value.
:c_msg
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
call echo %%MSGTXT%%
goto :eof

:c_title
echo.
echo ============================================================
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
call echo   %%MSGTXT%%
if defined VER echo   RTX3050Ti-8G-Toolkit v%VER%
echo ============================================================
goto :eof

:c_ok
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
call echo   [OK] %%MSGTXT%%
goto :eof

:c_warn
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
call echo   [WARN] %%MSGTXT%%
goto :eof

:c_err
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
call echo   [X] %%MSGTXT%%
goto :eof

:c_info
call :c_lookup "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8"
call echo   [i] %%MSGTXT%%
goto :eof

:c_die
call :c_err "err" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7"
echo.
pause
exit /b 1

rem ------------------------------------------------------------------ probe
rem Runs probe.ps1 and loads every key=value pair into the environment.
rem Sets PROBE_OK=1 on success, 0 when PowerShell or the script is missing.
:c_probe
set "PROBE_OK=0"
set "PROBE_FILE=%LOGS%\probe.txt"
if exist "%PROBE_FILE%" del /f /q "%PROBE_FILE%" >nul 2>&1
if not exist "%ROOT%\scripts\lib\probe.ps1" goto :eof
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\scripts\lib\probe.ps1" -Root "%ROOT%" -OutFile "%PROBE_FILE%" >nul 2>&1
if not exist "%PROBE_FILE%" goto :eof
for /f "usebackq tokens=1,* delims==" %%a in ("%PROBE_FILE%") do set "%%a=%%b"
if not "%PROBE_OK%"=="1" goto :eof
rem normalise values that may be empty
if not defined GPU_PRESENT set "GPU_PRESENT=0"
if not defined GPU_VRAM_MB set "GPU_VRAM_MB=0"
if not defined OS_BUILD set "OS_BUILD=0"
if not defined OS_ARCH set "OS_ARCH=%PROCESSOR_ARCHITECTURE%"
if not defined DISK_FREE_MB set "DISK_FREE_MB=0"
if not defined TASK_EXISTS set "TASK_EXISTS=0"
if not defined IS_ADMIN set "IS_ADMIN=0"
goto :eof

rem -------------------------------------------------------------------- smi
rem Prefer the bare command name: System32 is always on PATH and avoids the
rem quoting problems of for /f with "C:\Program Files\..."
:c_find_smi
if defined SMI_PATH if not "%SMI_PATH%"=="" goto :c_find_smi_have
set "SMI_PATH="
if exist "%SystemRoot%\System32\nvidia-smi.exe" set "SMI_PATH=%SystemRoot%\System32\nvidia-smi.exe"
if not defined SMI_PATH for %%P in (nvidia-smi.exe) do if not "%%~$PATH:P"=="" set "SMI_PATH=%%~$PATH:P"
if not defined SMI_PATH if exist "%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe" set "SMI_PATH=%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
:c_find_smi_have
set "SMI=nvidia-smi.exe"
if not defined SMI_PATH set "SMI=nvidia-smi.exe"
goto :eof

rem -------------------------------------------------------------------- gpu
:c_check_gpu
set "GPU_NAME="
set "GPU_FOUND=1"
if exist "%SystemRoot%\System32\nvidia-smi.exe" goto :c_check_gpu_smi
if defined SMI_PATH if exist "%SMI_PATH%" goto :c_check_gpu_smi
goto :eof
:c_check_gpu_smi
for /f "tokens=1 delims=," %%a in ('nvidia-smi.exe --query-gpu=name --format=csv^,noheader 2^>nul') do (
    set "GPU_NAME=%%a"
    set "GPU_FOUND=0"
)
goto :eof

:c_check_model
set "MODEL_OK=1"
if "%GPU_DEV%"=="25A0" set "MODEL_OK=0"
if not defined GPU_NAME goto :eof
echo %GPU_NAME% | findstr /i /c:"RTX 3050 Ti" >nul || goto :eof
echo %GPU_NAME% | findstr /i /c:"Laptop" >nul || goto :eof
set "MODEL_OK=0"
goto :eof

rem ------------------------------------------------------------------ admin
:c_is_admin
net session >nul 2>&1
if errorlevel 1 (set "ADMIN=0") else (set "ADMIN=1")
goto :eof

rem require_admin <script path> [first argument]
rem Relaunches the script elevated and always exits: the caller must stop.
:c_require_admin
rem test hook: lets an already-elevated CI shell skip the UAC relaunch
if /i "%RTXTOOLKIT_NO_ELEVATE%"=="1" exit /b 0
net session >nul 2>&1
if not errorlevel 1 exit /b 0
call "%LIB%" msg M0174
call "%LIB%" msg M0175
if "%~2"=="" (
    call "%LIB%" msg M0176
    exit /b 1
)
if not exist "%~2" (
    call "%LIB%" msg M0177 "%~2"
    exit /b 1
)
set "ELEV_ARG=%~3"
if not defined ELEV_ARG goto :c_require_admin_noarg
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~2' -ArgumentList '%ELEV_ARG%' -WorkingDirectory '%~dp2' -Verb RunAs" 2>nul
goto :c_require_admin_done
:c_require_admin_noarg
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~2' -WorkingDirectory '%~dp2' -Verb RunAs" 2>nul
:c_require_admin_done
if errorlevel 1 (
    call "%LIB%" msg M0178
    call "%LIB%" msg M0179
) else (
    call "%LIB%" msg M0180
)
exit /b 1

rem ------------------------------------------------------------------- hash
:c_sha256
set "HASH="
if not exist "%~2" exit /b 1
for /f "skip=1 delims=" %%h in ('certutil -hashfile "%~2" SHA256 2^>nul') do (
    if not defined HASH set "HASH=%%h"
)
if not defined HASH exit /b 1
set "HASH=%HASH: =%"
exit /b 0

rem check_file <path> <sha256|-> <label>
:c_check_file
if not exist "%~2" (
    call "%~dp0common.bat" err M0181 "%~3"
    call "%LIB%" msg M0182 "%~2"
    exit /b 1
)
if "%~3"=="-" exit /b 0
call "%~dp0common.bat" sha256 "%~2"
if errorlevel 1 (
    call "%~dp0common.bat" err M0183 "%~2"
    exit /b 1
)
if /i not "%HASH%"=="%~3" (
    call "%~dp0common.bat" err M0184 "%~3"
    call "%LIB%" msg M0185 "%~3"
    call "%LIB%" msg M0186
    call "%LIB%" msg M0187
    exit /b 1
)
exit /b 0

rem check_files <path> <size|-> <label>
:c_check_files
if not exist "%~2" (
    call "%~dp0common.bat" err M0188 "%~3"
    exit /b 1
)
if "%~3"=="-" exit /b 0
set "FSIZE=0"
for %%A in ("%~2") do set "FSIZE=%%~zA"
if not "%FSIZE%"=="%~3" (
    call "%~dp0common.bat" err M0189 "%~3"
    call "%LIB%" msg M0190 "%~3"
    exit /b 1
)
exit /b 0

rem ------------------------------------------------------------------ power
rem Reads power limits and stores both the displayed value (60.00) and the
rem integer part (60) so callers can use IF ... GTR safely.
:c_power_csv
set "PWR_DEF="
set "PWR_MAX="
set "PWR_MIN="
set "PWR_DEF_I="
set "PWR_MAX_I="
set "PWR_MIN_I="
if not exist "%SystemRoot%\System32\nvidia-smi.exe" if not defined SMI_PATH exit /b 0
for /f "tokens=1-3 delims=," %%a in ('nvidia-smi.exe --query-gpu=power.default_limit^,power.max_limit^,power.min_limit --format=csv^,noheader^,nounits 2^>nul') do (
    set "PWR_DEF=%%a"
    set "PWR_MAX=%%b"
    set "PWR_MIN=%%c"
)
if not defined PWR_DEF exit /b 0
set "PWR_DEF=%PWR_DEF: =%"
set "PWR_MAX=%PWR_MAX: =%"
set "PWR_MIN=%PWR_MIN: =%"
for /f "tokens=1 delims=." %%x in ("%PWR_DEF%") do set "PWR_DEF_I=%%x"
for /f "tokens=1 delims=." %%x in ("%PWR_MAX%") do set "PWR_MAX_I=%%x"
for /f "tokens=1 delims=." %%x in ("%PWR_MIN%") do set "PWR_MIN_I=%%x"
if not defined PWR_MIN_I set "PWR_MIN_I=1"
if not defined PWR_MAX_I set "PWR_MAX_I=0"
exit /b 0

rem ------------------------------------------------------------------ utils
:c_is_uint
set "V=%~2"
set "V=%V:W%"
set "V=%V:w%"
set "V=%V: =%"
if "%V%"=="" exit /b 1
set "NONNUM="
for /f "delims=0123456789" %%a in ("%V%") do set "NONNUM=%%a"
if defined NONNUM exit /b 1
exit /b 0

:c_log
if "%~2"=="" exit /b 0
>>"%~2" echo [%DATE% %TIME%] %~3
exit /b 0

:c_timestamp
set "TS="
for /f "delims=" %%t in ('powershell.exe -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss" 2^>nul') do set "TS=%%t"
if not defined TS set "TS=%RANDOM%"
exit /b 0

rem --------------------------------------------------------------- backup
rem backup_vbios - saves the vBIOS currently on the card to backups\
rem Sets BACKUP_OK=0 and BACKUP_FILE on success.
:c_backup_vbios
set "BACKUP_OK=1"
set "BACKUP_FILE="
rem nvflash blocks forever when it cannot open the display driver, so the
rem privilege check has to happen before the process is started.
net session >nul 2>&1
if errorlevel 1 (
    call "%~dp0common.bat" err M0380
    call "%~dp0common.bat" msg M0381
    exit /b 1
)
if not exist "%BACKUPS%" mkdir "%BACKUPS%" >nul 2>&1
if not exist "%TOOLS%\nvflashb.exe" (
    call "%~dp0common.bat" err M0191
    exit /b 1
)
call "%~dp0common.bat" timestamp
set "BACKUP_FILE=%BACKUPS%\vbios_%GPU_SUBSYS%_%TS%.rom"
if "%GPU_SUBSYS%"=="" set "BACKUP_FILE=%BACKUPS%\vbios_%TS%.rom"
"%TOOLS%\nvflashb.exe" --save "%BACKUP_FILE%" >"%LOGS%\backup_last.log" 2>&1
set "BSIZE=0"
if exist "%BACKUP_FILE%" for %%A in ("%BACKUP_FILE%") do set "BSIZE=%%~zA"
if %BSIZE% LSS 900000 (
    call "%~dp0common.bat" err M0192
    call "%LIB%" msg M0193
    call "%LIB%" msg M0194
    if exist "%BACKUP_FILE%" del /f /q "%BACKUP_FILE%" >nul 2>&1
    exit /b 1
)
set "BACKUP_OK=0"
call "%~dp0common.bat" log "%LOGS%\backup.log" "backup saved %BACKUP_FILE% (%BSIZE% bytes)"
exit /b 0

rem --------------------------------------------------------------- flashing
rem flash_rom <rom> <console log>
rem Sets FLASH_RC (0 = success) and FLASH_STATE (ok/verify/falcon/eeprom/
rem wprotect/nodev/unknown) plus FLASH_HINT for the caller.
:c_flash_rom
net session >nul 2>&1
if errorlevel 1 (
    call "%~dp0common.bat" err M0380
    call "%~dp0common.bat" msg M0381
    set "FLASH_RC=1"
    set "FLASH_STATE=nodev"
    set "FLASH_HINT="
    exit /b 1
)
set "FLASH_RC=1"
set "FLASH_STATE=unknown"
set "FLASH_HINT="
if not exist "%TOOLS%\nvflashb.exe" (
    call "%~dp0common.bat" err M0195
    exit /b 1
)
if not exist "%~2" (
    call "%~dp0common.bat" err M0196 "%~2"
    exit /b 1
)
if not exist "%LOGS%" mkdir "%LOGS%" >nul 2>&1
if exist "%~3" del /f /q "%~3" >nul 2>&1
set "NVLOG=%LOGS%\nvflash_last.log"
if exist "%NVLOG%" del /f /q "%NVLOG%" >nul 2>&1
"%TOOLS%\nvflashb.exe" --protectoff >>"%~3" 2>&1
"%TOOLS%\nvflashb.exe" --log="%NVLOG%" -6 "%~2" >>"%~3" 2>&1
set "FLASH_RC=%ERRORLEVEL%"
call "%~dp0common.bat" classify_flash "%~3"
exit /b 0

:c_classify_flash
set "FLASH_STATE=unknown"
set "FLASH_HINT="
set "CF1=%~2"
set "CF2=%LOGS%\nvflash_last.log"
findstr /i /c:"Update successful" "%CF1%" >nul 2>&1
if not errorlevel 1 set "FLASH_STATE=ok"
if not "%FLASH_STATE%"=="ok" if exist "%CF2%" (
    findstr /i /c:"Update successful" "%CF2%" >nul 2>&1
    if not errorlevel 1 set "FLASH_STATE=ok"
)
if "%FLASH_STATE%"=="ok" exit /b 0

findstr /i /c:"Invalid firmware image" /c:"VDPA_SIG_INVALID" /c:"CERT20" "%CF1%" >nul 2>&1
if not errorlevel 1 set "FLASH_STATE=verify"
if exist "%CF2%" (
    findstr /i /c:"VDPA_SIG_INVALID" /c:"CERT20" "%CF2%" >nul 2>&1
    if not errorlevel 1 set "FLASH_STATE=verify"
)
if "%FLASH_STATE%"=="verify" (
    call "%LIB%" msgs M0197
    set "FLASH_HINT=!MSGTXT!"
    exit /b 0
)

findstr /i /c:"Falcon In HALT" /c:"HALT or STOP" "%CF1%" >nul 2>&1
if not errorlevel 1 set "FLASH_STATE=falcon"
if "%FLASH_STATE%"=="falcon" (
    call "%LIB%" msgs M0198
    set "FLASH_HINT=!MSGTXT!"
    exit /b 0
)

findstr /i /c:"WRITE_PROTECT" /c:"write protect" /c:"Protection" "%CF1%" >nul 2>&1
if not errorlevel 1 set "FLASH_STATE=wprotect"
if "%FLASH_STATE%"=="wprotect" (
    call "%LIB%" msgs M0199
    set "FLASH_HINT=!MSGTXT!"
    exit /b 0
)

findstr /i /c:"EEPROM Program failed" /c:"OK_TO_FLASH" "%CF1%" >nul 2>&1
if not errorlevel 1 set "FLASH_STATE=eeprom"
if exist "%CF2%" (
    findstr /i /c:"OK_TO_FLASH" /c:"EWR" "%CF2%" >nul 2>&1
    if not errorlevel 1 set "FLASH_STATE=eeprom"
)
if "%FLASH_STATE%"=="eeprom" (
    call "%LIB%" msgs M0200
    set "FLASH_HINT=!MSGTXT!"
    exit /b 0
)

findstr /i /c:"No NVIDIA display adapters found" /c:"No display adapters" /c:"not found" "%CF1%" >nul 2>&1
if not errorlevel 1 set "FLASH_STATE=nodev"
if "%FLASH_STATE%"=="nodev" (
    call "%LIB%" msgs M0201
    set "FLASH_HINT=!MSGTXT!"
    exit /b 0
)
exit /b 0

rem -------------------------------------------------------- machine profile
rem Detects motherboard / GPU platform changes between runs.
rem Sets PROFILE_STATE=new|same|changed and PROFILE_CHANGED=0|1
:c_machine_profile
set "PROFILE_CHANGED=0"
set "PROFILE_STATE=new"
set "MP_FILE=%CONFIG%\machine_profile.txt"
if not exist "%MP_FILE%" goto :c_profile_write
set "OLD_DEV="
set "OLD_SUB="
set "OLD_VRAM="
for /f "usebackq tokens=1,* delims==" %%a in ("%MP_FILE%") do (
    if /i "%%a"=="gpu_dev" set "OLD_DEV=%%b"
    if /i "%%a"=="gpu_subsys" set "OLD_SUB=%%b"
    if /i "%%a"=="gpu_vram_mb" set "OLD_VRAM=%%b"
)
if not "%OLD_DEV%"=="%GPU_DEV%" set "PROFILE_CHANGED=1"
if not "%OLD_SUB%"=="%GPU_SUBSYS%" set "PROFILE_CHANGED=1"
if not "%OLD_VRAM%"=="%GPU_VRAM_MB%" set "PROFILE_CHANGED=1"
if "%PROFILE_CHANGED%"=="0" set "PROFILE_STATE=same"
if "%PROFILE_CHANGED%"=="1" set "PROFILE_STATE=changed"
if "%PROFILE_STATE%"=="same" exit /b 0
:c_profile_write
call "%~dp0common.bat" timestamp
> "%MP_FILE%" echo profile_version=1
>>"%MP_FILE%" echo first_seen=%DATE% %TIME%
>>"%MP_FILE%" echo gpu_dev=%GPU_DEV%
>>"%MP_FILE%" echo gpu_subsys=%GPU_SUBSYS%
>>"%MP_FILE%" echo gpu_vram_mb=%GPU_VRAM_MB%
>>"%MP_FILE%" echo gpu_name=%GPU_NAME%
exit /b 0

rem ------------------------------------------------------------------ trim
rem trim <varname> <value>  - drops the leading spaces nvidia-smi puts in
rem front of every CSV field, so fixed-width output stays aligned.
:c_trim
set "%~2=%~3"
for /f "tokens=* delims= " %%x in ("%~3") do set "%~2=%%x"
goto :eof

:c_version
echo %VER%
exit /b 0
