@echo off
set SCRIPT_DIR=%~dp0

echo Deploying config files to %USERPROFILE%
echo.

call :backup_and_copy "%SCRIPT_DIR%.emacs" "%USERPROFILE%\.emacs"
call :backup_and_copy "%SCRIPT_DIR%Windows\aliases.bat" "%USERPROFILE%\aliases.bat"

echo.
echo Done.
goto :eof

:backup_and_copy
set "src=%~1"
set "dest=%~2"
if not exist "%src%" (
    echo   SKIP %~nx1 (not found)
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
