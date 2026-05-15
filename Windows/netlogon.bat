@echo off
set delay=10
ping localhost -n %delay%
net use Z: "\\NAS\mikesa"
net use Z: "\\NAS\mikesa"
