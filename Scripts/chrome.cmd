
@echo off
if [%1]==[un]  goto uninstall

set prefs="%userprofile%\downloads\master_preferences.json" 

rem copy z:\installcmd\ChromeGpt.ini c:\windows\system32\GroupPolicy\gpt.ini /y
rem md c:\windows\system32\GroupPolicy\Machine
rem copy z:\installcmd\ChromeRegistry.pol c:\windows\system32\GroupPolicy\Machine\Registry.pol /y
rem GpUpdate.exe



echo { > %prefs%
echo  "browser": {"check_default_browser": false}, >> %prefs%
echo  "sync_promo" : {"show_on_first_run_allowed": false,  "user_skipped": true}, >> %prefs%
echo  "show-first-run-bubble-option": 1,  >> %prefs%
echo  "distribution" : { >> %prefs%
echo    "skip_first_run_ui" : true, >> %prefs%
echo    "show_welcome_page": false,    >> %prefs% 
echo    "create_all_shortcuts" : false, >> %prefs%
echo    "make_chrome_default" : false, >> %prefs%
echo    "make_chrome_default_for_user": false, >> %prefs%
echo    "suppress_first_run_default_browser_prompt": true, >> %prefs%
echo    "suppress_first_run_bubble": true, >> %prefs%
echo    "do_not_create_desktop_shortcut":true, >> %prefs%
echo    "do_not_create_quick_launch_shortcut":true, >> %prefs%
echo    "do_not_create_taskbar_shortcut":true, >> %prefs%
echo    "do_not_create_any_shortcuts" : true, >> %prefs%
echo    "msi":true, >> %prefs%
echo    "system_level":true, >> %prefs%
echo    "verbose_logging":true >> %prefs%
echo  } >> %prefs%
echo } >> %prefs%

md "c:\program files (x86)\Google"
md "c:\program files (x86)\Google\Chrome"
md "c:\program files (x86)\Google\Chrome\Application"

IF %processor_architecture%==x86 (
  copy %prefs% "c:\program files\Google\Chrome\Application\master_preferences" /y
) ELSE (
  copy %prefs% "c:\program files (x86)\Google\Chrome\Application\master_preferences" /y
)

msiexec /i "%userprofile%\downloads\googleChrome_setup.msi"   /passive

IF %processor_architecture%==x86 (
  copy %prefs% "c:\program files\Google\Chrome\Application\master_preferences" /y
) ELSE (
  copy %prefs% "c:\program files (x86)\Google\Chrome\Application\master_preferences" /y
)

::Manage Links
del "C:\Users\Public\Desktop\*chrome*.lnk"
move "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome\Google Chrome.lnk" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\"
IF EXIST "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome" rd /s /q "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome"
IF EXIST "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Google Chrome" rd /s /q "%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Google Chrome"


goto :eof

:uninstall

MsiExec.exe /X "%userprofile%\downloads\googleChrome_setup.msi" /passive
IF EXIST "%AppData%\google" rd "%AppData%\google"   /s /q
IF EXIST "%AppData%\..\local\google" rd "%AppData%\..\local\google"   /s /q
IF EXIST "c:\program files\Google" rd "c:\program files\Google" /s /q
IF EXIST "c:\program files (x86)\Google" rd "c:\program files (x86)\Google" /s /q



