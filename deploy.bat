@echo off
setlocal
set SCRIPT_DIR=%~dp0

echo Deploying config files to %USERPROFILE%
echo.

call :backup_and_copy "%SCRIPT_DIR%.emacs" "%USERPROFILE%\.emacs"
call :backup_and_copy "%SCRIPT_DIR%Windows\aliases.bat" "%USERPROFILE%\aliases.bat"

rem PowerShell profile: ask each installed PowerShell where its per-user,
rem per-host profile lives (the path differs between Windows PowerShell 5.1
rem and pwsh 7, and may be OneDrive-redirected), then install there.
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "$PROFILE.CurrentUserCurrentHost"`) do call :deploy_ps_profile "%%p"
where pwsh >nul 2>&1
if not errorlevel 1 for /f "usebackq delims=" %%p in (`pwsh -NoProfile -Command "$PROFILE.CurrentUserCurrentHost"`) do call :deploy_ps_profile "%%p"

echo.
echo Done.
goto :eof

:deploy_ps_profile
for %%d in ("%~1") do if not exist "%%~dpd" mkdir "%%~dpd"
call :backup_and_copy "%SCRIPT_DIR%Windows\Microsoft.PowerShell_profile.ps1" "%~1"
goto :eof

:backup_and_copy
set "src=%~1"
set "dest=%~2"
if not exist "%src%" (
    echo   SKIP %~nx1 ^(not found^)
    goto :eof
)
if exist "%dest%" (
    fc /b "%src%" "%dest%" >nul 2>&1
    if not errorlevel 1 (
        echo   UNCHANGED %~nx2
        goto :eof
    )
    copy /y "%dest%" "%dest%.bak" >nul
    echo   BACKUP %dest% -^> %dest%.bak
)
copy /y "%src%" "%dest%" >nul
echo   INSTALLED %dest%
goto :eof
