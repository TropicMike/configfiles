@echo off
setlocal
set SCRIPT_DIR=%~dp0
rem Set to 1 by :backup_and_copy on any failure; makes the script exit 1.
set FAILED=0

echo Deploying config files to %USERPROFILE%
echo.

call :backup_and_copy "%SCRIPT_DIR%.emacs" "%USERPROFILE%\.emacs"
call :backup_and_copy "%SCRIPT_DIR%Windows\aliases.bat" "%USERPROFILE%\aliases.bat"

rem OpenCode reads its global config from %XDG_CONFIG_HOME%\opencode, falling
rem back to %USERPROFILE%\.config\opencode.
if defined XDG_CONFIG_HOME (set "OPENCODE_DIR=%XDG_CONFIG_HOME%\opencode") else (set "OPENCODE_DIR=%USERPROFILE%\.config\opencode")
rem Only deploy if OpenCode is installed: on PATH, or in its installer's
rem default location.
where opencode >nul 2>&1
if not errorlevel 1 goto :have_opencode
if exist "%USERPROFILE%\.opencode\bin\opencode.exe" goto :have_opencode
echo   SKIP opencode.jsonc ^(opencode not installed^)
goto :end_opencode
:have_opencode
if not exist "%OPENCODE_DIR%" mkdir "%OPENCODE_DIR%"
rem The Obsidian vault (and the AI-memory notes OpenCode loads from it) lives
rem outside this repo, so opencode.jsonc holds a placeholder for its glob.
rem Fill in this machine's path; OBSIDIAN_VAULT overrides the default below.
if defined OBSIDIAN_VAULT (set "VAULT_DIR=%OBSIDIAN_VAULT%") else (set "VAULT_DIR=%USERPROFILE%\Documents\MJS-Obsidian-Vault")
if exist "%VAULT_DIR%\AI-memory" goto :have_ai_memory
echo   WARNING: no AI-memory folder at "%VAULT_DIR%"
echo            set OBSIDIAN_VAULT to your vault, or AI memory will not load
:have_ai_memory
rem JSON needs forward slashes in the glob, not Windows backslashes.
set "AI_MEMORY_GLOB=%VAULT_DIR%\AI-memory\*.md"
set "AI_MEMORY_GLOB=%AI_MEMORY_GLOB:\=/%"
rem Render the placeholder into a temp copy, then install that through
rem :backup_and_copy so backup, unchanged-skip and atomic install still apply.
set "OPENCODE_SRC=%SCRIPT_DIR%opencode\opencode.jsonc"
set "OPENCODE_TMP=%TEMP%\opencode-rendered.jsonc"
powershell -NoProfile -Command "$t = [IO.File]::ReadAllText($env:OPENCODE_SRC); [IO.File]::WriteAllText($env:OPENCODE_TMP, $t.Replace('__AI_MEMORY_GLOB__', $env:AI_MEMORY_GLOB))"
if errorlevel 1 goto :render_failed
call :backup_and_copy "%OPENCODE_TMP%" "%OPENCODE_DIR%\opencode.jsonc"
if exist "%OPENCODE_TMP%" del "%OPENCODE_TMP%" >nul 2>&1
goto :end_opencode
:render_failed
echo   ERROR rendering opencode.jsonc
set FAILED=1
:end_opencode

rem PowerShell profile: ask each installed PowerShell where its per-user,
rem per-host profile lives (the path differs between Windows PowerShell 5.1
rem and pwsh 7, and may be OneDrive-redirected), then install there.
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "$PROFILE.CurrentUserCurrentHost"`) do call :deploy_ps_profile "%%p"
where pwsh >nul 2>&1
if not errorlevel 1 for /f "usebackq delims=" %%p in (`pwsh -NoProfile -Command "$PROFILE.CurrentUserCurrentHost"`) do call :deploy_ps_profile "%%p"

rem Git Bash (if installed) sources ~/.bashrc like Linux and can use the
rem shared .aliases, so deploy both.
if exist "%ProgramFiles%\Git\bin\bash.exe" goto :have_gitbash
if exist "%LocalAppData%\Programs\Git\bin\bash.exe" goto :have_gitbash
goto :end_gitbash
:have_gitbash
call :backup_and_copy "%SCRIPT_DIR%.aliases" "%USERPROFILE%\.aliases"
call :backup_and_copy "%SCRIPT_DIR%Linux\.bashrc" "%USERPROFILE%\.bashrc"
:end_gitbash

echo.
if "%FAILED%"=="1" (
    echo Done, with errors ^(see the ERROR lines above^).
    exit /b 1
)
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
rem The steps below use goto rather than ( ) blocks so that a path containing
rem a parenthesis (e.g. "Program Files (x86)") can't break the echo lines.
if not exist "%dest%" goto :install
fc /b "%src%" "%dest%" >nul 2>&1
if not errorlevel 1 (
    echo   UNCHANGED %~nx2
    goto :eof
)
copy /y "%dest%" "%dest%.bak" >nul
if errorlevel 1 goto :backup_failed
echo   BACKUP %dest% -^> %dest%.bak
:install
rem Copy to a temp file next to the destination and move it into place, so a
rem failed copy (locked file, permissions, OneDrive) can never leave a
rem truncated file at the destination.
copy /y "%src%" "%dest%.tmp" >nul
if errorlevel 1 goto :copy_failed
move /y "%dest%.tmp" "%dest%" >nul
if errorlevel 1 goto :install_failed
echo   INSTALLED %dest%
goto :eof

:backup_failed
echo   ERROR backing up %dest% (leaving it untouched)
set FAILED=1
goto :eof

:copy_failed
if exist "%dest%.tmp" del "%dest%.tmp"
echo   ERROR copying %src% -^> %dest%
set FAILED=1
goto :eof

:install_failed
if exist "%dest%.tmp" del "%dest%.tmp"
echo   ERROR installing %dest%
set FAILED=1
goto :eof
