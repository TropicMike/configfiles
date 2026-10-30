@echo off
rem Bootstrap the baseline tool set on a new Windows machine via winget.
rem Idempotent: --no-upgrade makes winget skip packages that are already
rem installed rather than upgrading them (requires winget 1.7 or later). Run
rem deploy.bat afterwards to install the config files themselves.
setlocal

rem winget ships with the "App Installer" Store package, which LTSC and Server
rem images don't include; fail with a clear message instead of an opaque error.
where winget >nul 2>&1
if errorlevel 1 (
    echo winget was not found. Install App Installer from the Microsoft Store
    echo or from https://aka.ms/getwinget, then re-run this script.
    exit /b 1
)

for %%i in (
    Git.Git
    GitHub.cli
    jftuga.less
) do (
    echo === %%i ===
    winget install --id %%i -e --no-upgrade --source winget --accept-package-agreements --accept-source-agreements
)

echo.
echo Done. Open a new terminal to pick up PATH changes, then run deploy.bat.
