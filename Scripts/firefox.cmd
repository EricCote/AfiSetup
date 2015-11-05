@Echo off
set dl=c:\dl

if [%1]==[un]   goto uninstall
if NOT [%1]==[]  set dl=%1

@SET Progs=c:\program files (x86)

@IF %processor_architecture%==x86 (
  @SET Progs=c:\program files
)


@SET Prefs=%progs%\mozilla firefox\browser\defaults\preferences
@SET FireFolder=%progs%\mozilla firefox

SET iniFile="%dl%\firefox.ini"

echo [Install] > %iniFile%
echo QuickLaunchShortcut=false >> %iniFile% 
echo DesktopShortcut=false >> %iniFile%

"%dl%\firefox_setup.exe" -ms /ini=%iniFile%

del %iniFile%

@md "%prefs%"
@echo pref("browser.shell.checkDefaultBrowser", false); > "%prefs%\all-afi.js"
@echo pref("startup.homepage_welcome_url", ""); >> "%prefs%\all-afi.js"
@echo pref("browser.usedOnWindows10", true); >> "%prefs%\all-afi.js"
@echo pref("browser.startup.homepage", "data:text/plain,browser.startup.homepage=http://www.afiexpertise.com/fr/"); >> "%prefs%\all-afi.js"
::@echo pref("general.useragent.locale", "fr"); >> "%prefs%\all-afi.js"
@echo pref("intl.locale.matchOS", true); >> "%prefs%\all-afi.js"
@echo pref("toolkit.telemetry.prompted", 2); >> "%prefs%\all-afi.js"
@echo pref("toolkit.telemetry.rejected", true); >> "%prefs%\all-afi.js"
@echo pref("toolkit.telemetry.enabled", false); >> "%prefs%\all-afi.js"
@echo pref("datareporting.healthreport.service.enabled", false); >> "%prefs%\all-afi.js"
@echo pref("datareporting.healthreport.uploadEnabled", false); >> "%prefs%\all-afi.js"
@echo pref("datareporting.healthreport.service.firstRun", false); >> "%prefs%\all-afi.js"
@echo pref("datareporting.healthreport.logging.consoleEnabled", false); >> "%prefs%\all-afi.js"
@echo pref("datareporting.policy.dataSubmissionEnabled", false); >> "%prefs%\all-afi.js"
@echo pref("datareporting.policy.dataSubmissionPolicyResponseType", "accepted-info-bar-dismissed"); >> "%prefs%\all-afi.js"
@echo pref("datareporting.policy.dataSubmissionPolicyAccepted", false); >>"%prefs%\all-afi.js"

@echo [XRE] > "%FireFolder%\browser\override.ini"
@echo EnableProfileMigrator=false >> "%FireFolder%\browser\override.ini"

@md "%FireFolder%\distribution\extensions"

@for  %%A in (%dl%\fr*lang*.xpi) DO (
 @copy "%%A"  "%FireFolder%\distribution\extensions\langpack-fr@firefox.mozilla.org.xpi" /y
)

::del c:\users\public\desktop\mozilla*.*

goto :eof

:uninstall
"C:\Program Files (x86)\Mozilla Firefox\uninstall\helper.exe" /silent
rd  "%appData%\mozilla" /s /q
rd  "%appData%\..\local\mozilla" /s /q
rd "c:\program files (x86)\mozilla firefox" /s /q
del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\*firefox*.*"
