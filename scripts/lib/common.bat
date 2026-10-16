@echo off
chcp 65001 >nul
rem ============================================================================
rem common.bat - RTX3050Ti-8G-Toolkit ( )
rem : set LIB=%%~dp0lib\common.bat,
rem :
rem 1) setlocal,
rem 2) cmd ,
rem 3) ,
rem ============================================================================

if "%~1"=="" goto :eof

if /i "%~1"=="init"           goto :c_init
if /i "%~1"=="title"          goto :c_title
if /i "%~1"=="ok"             goto :c_ok
if /i "%~1"=="warn"           goto :c_warn
if /i "%~1"=="err"            goto :c_err
if /i "%~1"=="info"           goto :c_info
if /i "%~1"=="die"            goto :c_die
if /i "%~1"=="find_smi"       goto :c_find_smi
if /i "%~1"=="check_gpu"      goto :c_check_gpu
if /i "%~1"=="check_model"    goto :c_check_model
if /i "%~1"=="require_admin"  goto :c_require_admin
if /i "%~1"=="is_admin"       goto :c_is_admin
if /i "%~1"=="check_files"    goto :c_check_files
if /i "%~1"=="power_csv"      goto :c_power_csv
if /i "%~1"=="is_uint"        goto :c_is_uint
if /i "%~1"=="log"            goto :c_log
goto :eof

rem ------------------------------------------------------------------ init
:c_init
for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
set "TOOLS=%ROOT%\tools"
set "ROMS=%ROOT%\roms"
set "CONFIG=%ROOT%\config"
set "LOGS=%ROOT%\logs"
if not exist "%LOGS%" mkdir "%LOGS%" >nul 2>&1
if not exist "%CONFIG%" mkdir "%CONFIG%" >nul 2>&1
goto :eof

rem ----------------------------------------------------------------- output
:c_title
echo.
echo ============================================================
echo   %~2
echo ============================================================
goto :eof

:c_ok
echo   [OK] %~2
goto :eof

:c_warn
echo   [!] %~2
goto :eof

:c_err
echo   [X] %~2
goto :eof

:c_info
echo   [i] %~2
goto :eof

:c_die
call "%~dp0common.bat" err %~2
echo.
pause
exit /b 1

rem -------------------------------------------------------------------- smi
:c_find_smi
set "SMI="
if exist "%SystemRoot%\System32\nvidia-smi.exe" set "SMI=%SystemRoot%\System32\nvidia-smi.exe"
if not defined SMI for %%P in (nvidia-smi.exe) do if not "%%~$PATH:P"=="" set "SMI=%%~$PATH:P"
if not defined SMI if exist "%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe" set "SMI=%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
if not defined SMI set "SMI=nvidia-smi.exe"
goto :eof

rem -------------------------------------------------------------------- gpu
:c_check_gpu
set "GPU_NAME="
set "GPU_FOUND=1"
for /f "tokens=1 delims=," %%a in ('"%SMI%" --query-gpu=name --format=csv^,noheader 2^>nul') do (
    set "GPU_NAME=%%a"
    set "GPU_FOUND=0"
)
goto :eof

:c_check_model
set "MODEL_OK=1"
echo !GPU_NAME! | findstr /i "3050" >nul && set "MODEL_OK=0"
echo !GPU_NAME! | findstr /i "Laptop" >nul && set "MODEL_OK=0"
goto :eof

rem ------------------------------------------------------------------ admin
:c_is_admin
net session >nul 2>&1
if errorlevel 1 (set "ADMIN=0") else (set "ADMIN=1")
goto :eof

:c_require_admin
net session >nul 2>&1
if not errorlevel 1 exit /b 0
echo   [i] 本操作需要管理员权限, 正在自动请求提权...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~2' -ArgumentList '%~3 %~4 %~5 %~6 %~7' -Verb RunAs" >nul 2>&1
if errorlevel 1 echo   [X] 自动提权失败, 请右键脚本选择"以管理员身份运行"。
exit /b 1

rem ------------------------------------------------------------------ files
rem check_files < > < , > < >
:c_check_files
if not exist "%~2" (
    call "%~dp0common.bat" err "缺少文件: %~2 [%~4]"
    exit /b 1
)
if "%~3"=="" exit /b 0
set "FSIZE=0"
for %%A in ("%~2") do set "FSIZE=%%~zA"
if not "!FSIZE!"=="%~3" (
    call "%~dp0common.bat" err "文件大小异常: %~2 期望 %~3 字节 实际 !FSIZE! 字节"
    exit /b 1
)
exit /b 0

rem ------------------------------------------------------------------ power
:c_power_csv
set "PWR_DEF="
set "PWR_MAX="
for /f "tokens=1,2 delims=," %%a in ('"%SMI%" --query-gpu=power.default_limit^,power.max_limit --format=csv^,noheader^,nounits 2^>nul') do (
    set "PWR_DEF=%%a"
    set "PWR_MAX=%%b"
    set "PWR_DEF=!PWR_DEF: =!"
    set "PWR_MAX=!PWR_MAX: =!"
)
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
>>"%~2" echo [%DATE% %TIME%] %~3
exit /b 0
