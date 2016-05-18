#REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TBDEn"  `
#        /v SBOEM0 /t REG_EXPAND_SZ `
#        /d "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Mozilla Firefox.lnk" /f

#        REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TBDEn"  `
#        /v SBOEM1 /t REG_EXPAND_SZ `
#        /d "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk" /f

#        REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TBDEn"  `
#        /v SBOEM2 /t REG_EXPAND_SZ `
#        /d "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Opera.lnk" /f




#Issues:
#Takes 2 seconds to add a pinned program

#Should NEVER use on an already pinned program
#There is no way for this function to  detect that an app is already pinned.

#if an app is already pinned when we run, it will either:
#a. pin it to start menu
#b. unpin it from the taskbar if it's already on the start menu.

function Pin-ToTaskbar
{   
    param 
    (
        [parameter(position=1,mandatory=$true)] $appName
    )   

    Add-Type -AssemblyName System.Windows.Forms

    
    [System.Windows.Forms.SendKeys]::SendWait("^{ESC}") # Ctrl-Esc to call start menu 
    start-sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait($appname) # type app name 
    start-sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("+{F10}")  # Shift-F10 to call right-click menu
    start-sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait("{DOWN}{DOWN}{DOWN}{DOWN}") # down 4 times,
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}") # enter
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}") # escape
}

Pin-Application "Google Chrome"
Pin-Application "Mozilla Firefox"
Pin-Application "Opera"
Pin-Application "Visual Studio 2015"



