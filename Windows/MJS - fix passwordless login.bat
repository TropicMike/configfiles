rem Run as admin
rem From https://www.askvg.com/fix-users-must-enter-a-user-name-and-password-to-use-this-computer-checkbox-missing-in-windows-10/
rem Setting DevicePasswordLessBuildVersion=0 un-hides the "Users must enter a
rem user name and password" checkbox in netplwiz.
reg ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device" /v DevicePasswordLessBuildVersion /t REG_DWORD /d 0 /f
pause
