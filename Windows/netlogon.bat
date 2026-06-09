@echo off
rem Maps the NAS share to Z: at logon, after a delay for the network to come up.
rem Wait ~9s for the network to come up before mapping.
timeout /t 9 /nobreak >nul
net use Z: "\\NAS\mikesa"
