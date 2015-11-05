@echo off

SET dl=c:\dl

IF [%1]==[un]  goto uninstall
IF NOT [%1]==[] SET dl=%1


"%dl%\opera_setup.exe" /install /runimmediately  /language=en-US /launchopera=0 /setdefaultbrowser=0 /startmenushortcut=1 /desktopshortcut=0 /quicklaunchshortcut=0 /pintotaskbar=0 /allusers=1 > nul

rem --with-feature:scheduled-autoupdate=0 

@set defaultdata=c:\users\default\appData\roaming
@md "%appData%\Opera Software\Opera Stable"
@md "%defaultData%\Opera Software"
@md "%defaultData%\Opera Software\Opera Stable"

@echo { "browser": { "check_default_browser": false } } > "%appData%\Opera Software\Opera Stable\preferences"

@copy "%appData%\Opera Software\Opera Stable\preferences" "%defaultData%\Opera Software\Opera Stable\preferences" /y


goto :eof

:uninstall
"c:\Program Files (x86)\Opera\launcher.exe" /silent /uninstall
IF EXIST "%appData%\Opera Software" rd "%appData%\Opera Software" /s /q
IF EXIST "%AppData%\..\local\Opera Software"  rd "%AppData%\..\local\Opera Software" /s /q
IF EXIST "c:\users\default\appData\roaming\Opera Software" rd "c:\users\default\appData\roaming\Opera Software" /s /q
timeout 3 > null
IF EXIST "c:\Program Files (x86)\Opera" rd "c:\Program Files (x86)\Opera" /s /q


