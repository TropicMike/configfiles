@echo off
rem Bootstrap the baseline tool set on a new Windows machine via winget.
rem Idempotent: --no-upgrade makes winget skip packages that are already
rem installed rather than upgrading them. Run deploy.bat afterwards to
rem install the config files themselves.
setlocal

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
