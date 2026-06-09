@echo off
rem Maps the NAS share to Z: at logon, after a delay for the network to come up.
rem Wait ~9s for the network to come up before mapping (ping -n N ~= N-1 second
rem delay). Not timeout: it errors out instantly when stdin is not a console.
ping localhost -n 10 >nul
net use Z: "\\NAS\mikesa"
