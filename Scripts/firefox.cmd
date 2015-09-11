@Echo off

if [%1]==[un]   goto uninstall

@SET Progs=c:\program files (x86)


@IF %processor_architecture%==x86 (
  @SET Progs=c:\program files
)



@SET Prefs=%progs%\mozilla firefox\browser\defaults\preferences
@SET FireFolder=%progs%\mozilla firefox

SET iniFile="%userprofile%\downloads\firefox.ini" 

echo [Install] > %iniFile%
echo QuickLaunchShortcut=false >> %iniFile% 
echo DesktopShortcut=false >> %iniFile%

"%userprofile%\downloads\firefox_setup.exe" -ms /ini=%iniFile%

del %iniFile%

@md "%prefs%"
@echo pref("browser.shell.checkDefaultBrowser", false); > "%prefs%\all-afi.js"
@echo pref("startup.homepage_welcome_url", ""); >> "%prefs%\all-afi.js"
@echo pref("browser.usedOnWindows10", true); >> "%prefs%\all-afi.js"
::@echo pref("browser.startup.homepage", "data:text/plain,browser.startup.homepage=http://www.afiexpertise.com/fr/"); >> "%prefs%\all-afi.js"
::@echo pref("general.useragent.locale", "en"); >> "%prefs%\all-afi.js"

@echo [XRE] > "%FireFolder%\browser\override.ini"
@echo EnableProfileMigrator=false >> "%FireFolder%\browser\override.ini"

@md "%FireFolder%\distribution\extensions"

@for  %%A in (%userprofile%\downloads\fr*lang*.xpi) DO (
 @copy "%%A"  "%FireFolder%\distribution\extensions\langpack-fr@firefox.mozilla.org.xpi" /y
)

::del c:\users\public\desktop\mozilla*.*

goto :eof

:uninstall
"C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe" /silent
rd  "%appData%\mozilla" /s /q
rd  "%appData%\..\local\mozilla" /s /q
rd "c:\program files (x86)\mozilla firefox" /s /q
del c:\users\public\desktop\mozilla*.*