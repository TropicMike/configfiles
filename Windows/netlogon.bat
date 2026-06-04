@echo off
rem Maps the NAS share to Z: at logon, after a delay for the network to come up.
rem Wait ~9s for the network to come up (ping -n N ~= N-1 second delay) before mapping.
set delay=10
ping localhost -n %delay%
net use Z: "\\NAS\mikesa"
