
$dl=$env:USERPROFILE + "\downloads\"
$stepFile=$dl + "step.txt"


If (!(Test-Path $stepFile)){
   "1">$stepFile
}

$step=(get-content $stepfile)

$OsVersion=[Environment]::OSVersion.Version.Major 
$isServer= (Gwmi  Win32_OperatingSystem).productType -gt 1


function Set-Background
{

    Param([parameter(Position=1)]
      $NewColor
    )

        $code=@'
          public const int SetDesktopWallpaper = 20;
          public const int UpdateIniFile = 0x01;
          public const int SendWinIniChange = 0x02;
          public const int ColorDesktop = 1;

          [DllImport("user32.dll")]
          public static extern bool SetSysColors(int cElements, int[] lpaElements, int[] lpaRgbValues);

          [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
          public static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
'@

    add-type -Namespace Win32 -Name Desk -MemberDefinition  $code


    $theColor=[System.Drawing.Color]::FromName($NewColor)

    if ($theColor.ToArgb() -ne 0)
    {
        $oldWallpaper=Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper"
        $oldBackground=    Get-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background"
        
        try{
            $saved=Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "OldWallpaper" -ErrorAction SilentlyContinue
        }
        catch {
            $saved=$null
        }
        if ($saved -eq $null){
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "OldWallpaper" -Value $oldWallpaper.Wallpaper
            Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "OldBackground" -Value $oldBackground.Background
        }

        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value ($theColor.R + " " + $theColor.G + " " +$theColor.B)
        [Win32.Desk]::SystemParametersInfo([Win32.Desk]::SetDesktopWallpaper,0,"",[Win32.Desk]::UpdateIniFile -bor [Win32.Desk]::SendWinIniChange)

        $myOperations= @([Win32.Desk]::ColorDesktop) 
        $myColors=@([System.Drawing.ColorTranslator]::ToWin32([System.Drawing.Color]::FromName($NewColor)))
        [Win32.Desk]::SetSysColors($myOperations.Length, $myOperations, $myColors)
    }
    else{
        $oldWallpaper=$null
        $oldWallpaper=Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "OldWallpaper" -ErrorAction SilentlyContinue
        $oldBackground=Get-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "OldBackground" -ErrorAction SilentlyContinue
        if ($oldWallpaper -eq $null){
            return
        }

        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "Background" -Value $oldBackground.OldBackground

        $myOperations= @([Win32.Desk]::ColorDesktop) 
        $myColors=@([System.Drawing.ColorTranslator]::ToWin32([System.Drawing.Color]::FromName($NewColor)))
        [Win32.Desk]::SetSysColors($myOperations.Length, $myOperations, $myColors)
            
        [Win32.Desk]::SystemParametersInfo([Win32.Desk]::SetDesktopWallpaper,0,$oldWallpaper.OldWallpaper,[Win32.Desk]::UpdateIniFile -bor [Win32.Desk]::SendWinIniChange)

        Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "OldWallpaper" 
        Remove-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name "OldBackground"
    }

}



function Download-File
{
    Param([parameter(Position=1)]
      $Source, 
      [parameter(Position=2)]
      $Destination
    )

    $wc = new-object System.Net.WebClient
    $wc.DownloadFile($Source,$Destination)
    $wc.Dispose()
}

function Detect-ShiftKeyDown
{
    Add-Type -AssemblyName System.Windows.Forms
    return [System.Windows.Forms.Control]::ModifierKeys -eq "Shift"
}


function Get-ScriptPath
{

  if ($MyInvocation.PSScriptRoot) 
  {
     return $MyInvocation.PSScriptRoot
  }
  else
  {
    return "c:\scripts"
  }

}


function Update-StoreApps
{      

    Add-Type -AssemblyName System.Windows.Forms

    start ms-windows-store:updates 
    start-sleep -Milliseconds 4000
    [System.Windows.Forms.SendKeys]::SendWait("~")
    start-sleep -Milliseconds 6000
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
}

function Disable-IEESC
{
    $AdminKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
    $UserKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
    Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
    Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0
}

function Install-MediaFeatures
{
#detect windows version for client
    if (-NOT $isserver)
    {
        $HasMedia='disabled'
        $HasMedia=(Get-WindowsOptionalFeature -online -FeatureName MediaPlayback).State


        #detect if windows media playback is not installed
        if ($HasMedia -ne 'Enabled' -and $OsVersion -eq 10)
        {
            "Downloading Media Pack...."
            #Download Media feature pack
            Download-file "http://download.microsoft.com/download/7/F/2/7F2E00A7-F071-41CA-A35B-00DC536D4227/Windows10-KB3010081-x64.msu" `
                            ( $dl + "Windows10-KB3010081-x64.msu") 
                
            "Installing Media Pack"
            #install Media feature pack
            $wusaArgs =  '"' + $dl + '\Windows10-KB3010081-x64.msu" /quiet /norestart'
            Start-Process wusa.exe -ArgumentList $wusaArgs -Wait
        }
    }
    else #is windows server
    {
        Install-WindowsFeature Desktop-Experience
        Set-Service audiosrv -startuptype automatic

        Disable-IEESC
           
        Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced TaskBarSizeMove "0"
        Stop-Process -Name Explorer
    }
}


function Configure-MSUpdate
{
    $ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
    $ServiceManager.ClientApplicationID = "My App"
    $status=$ServiceManager.QueryServiceRegistration("7971f918-a847-4430-9279-4a52d1efe18d").RegistrationState
    if ($status -lt 3)
    {
        $ServiceManager.AddService2( "7971f918-a847-4430-9279-4a52d1efe18d",7,"")
    }
}


function Set-AutoLogon 
{
    param
    (
        $domainName,
        $loginName,
        $password,
        $count = 0
    )


    if ($domainName)
    {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomainName -Value $domainName
    }
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName  -Value $loginName 
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword  -Value $password 
    if ($count -gt 0)
    {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value $count 
    }
}




function Install-FrenchLanguagePack
{
    $LanguagePackSource=""

    if (-NOT $isserver -and $OsVersion -eq 10)
    {             
        $LanguagePackSource = "http://download.windowsupdate.com/d/msdownload/update/software/updt/2015/07/lp_8f6e1d4cb3972edef76030b917020b7ee6cf6582.cab"
    }
       
    if ($isServer -and $OsVersion -lt 10)
    {
        $LanguagePackSource = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2014/11/windows8.1-kb3012997-x64-fr-fr-server_f5e444a46e0b557f67a0df7fa28330f594e50ea7.cab"
    }      
       
    if (-NOT $isServer -and $OsVersion -lt 10)
    {
        $LanguagePackSource = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2014/11/windows8.1-kb3012997-x64-fr-fr-client_134770b2c1e1abaab223d584d0de5f3b4d683697.cab"
    }       
        
    $fr=$dl + "fr.cab"
   
    Download-file $LanguagePackSource $fr
    Add-WindowsPackage -Online -PackagePath ($fr)
}

function Install-FrenchKeyboardsAndDictionaries
{
    if (-NOT $isserver -and $OsVersion -eq 10)
    {      
        #Get-WindowsCapability -online
        #add-WindowsCapability -online -name Language.Basic~~~fr-FR~0.0.1.0
        add-WindowsCapability -online -name Language.Basic~~~fr-CA~0.0.1.0
        add-WindowsCapability -online -name Language.OCR~~~fr-CA~0.0.1.0
    }

    $lang=Get-WinUserLanguageList 
    $lang.add("fr-CA")
    Set-WinUserLanguageList $lang -force
}

function Set-LanguageAndKeyboard
{
    param 
    (
        [parameter(position=1,mandatory=$true)]
        [ValidateSet("en-US.xml","fr-FR.xml","fr-CA.xml")] $fileName
    )

    $confPath = Join-Path (Get-ScriptPath) $fileName
    $arguments = 'intl.cpl,, /f:"' + $confPath + '"'
    Start-Process control.exe -ArgumentList ($arguments)     
}

#Get VS Setup filepath exe  (ex: Vs_enterprise.exe or vs_community.exe) 
function Get-VsSetupPath
{
    $result = dir -Path "C:\ProgramData\Package Cache\" -Name "vs_*.exe" -Exclude "vs_*[ps].exe" -Recurse
    return  ("C:\ProgramData\Package Cache\" + $result)
}

function Initialize-IE 
{
    md 'HKLM:\Software\Policies\Microsoft\Internet Explorer'
    md 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Main'
    New-ItemProperty -path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -name "DisableFirstRunCustomize" -value 1
        
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName Microsoft.VisualBasic

    Start-Process 'C:\Program Files (x86)\Internet Explorer\iexplore.exe'  
    start-sleep -Milliseconds 5000

    $proc=get-process -Name iexplore
     
    #[Microsoft.VisualBasic.Interaction]::AppActivate($proc[0].id)
    start-sleep -Milliseconds 1000
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
        
}


function Install-VSExtension 
{
    param
    (
        [Parameter(position=1, Mandatory=$True)] $source
    )

    $destination = $dl + (Split-Path  $source -Leaf)

    #get the extension
    Download-File $source $destination

    #install the extension
    Start-Process "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\vsixinstaller.exe" -ArgumentList ('-q "' + $destination  + '"')  -Wait 
}

 function Initialize-VisualStudio     
{
    $char="%{F4}"
    if($vsProduct -eq "community") {
    $char="{ESCAPE}{ENTER}%{F4}{TAB}"
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName Microsoft.VisualBasic


    start-process "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\devenv.exe" -ArgumentList "/resetSettings general.vssettings"
    start-sleep -Milliseconds 120000
    $proc= Get-Process -name devenv
    do {
        [Microsoft.VisualBasic.Interaction]::AppActivate($proc[0].id)
        start-sleep -Milliseconds 1500
        [System.Windows.Forms.SendKeys]::SendWait($char)
        start-sleep -Milliseconds 15000
    }
    until ($proc.HasExited)
}


function Show-Warning
{
    Write-Host "========================================================================================" -ForegroundColor Yellow
    Write-Host "DO NOT INTERACT with this computer, unless the script is finished " -ForegroundColor Yellow
    Write-Host "or there is an error message." -ForegroundColor Yellow
    Write-Host "The computer will reboot a few times" -ForegroundColor Yellow
    Write-Host "Thank you!" -ForegroundColor Yellow
    Write-Host "=========================================================================================" -ForegroundColor Yellow
}

if (Detect-ShiftKeyDown)
{
   "bye!"
    return 
}
 
switch ($step)
{

   1
   {
        #Check if admin
        If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
        {
            "not an admin!!!"
            return
        }

        Show-Warning

       "installation du poste"
        #Disable the script execution policy for future scripts that are running 
        Set-ExecutionPolicy bypass
    
        #Show hidden Files
        Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt "0"

        #Put right time zone
        tzutil /s "Eastern Standard Time"


        #If windows client
        if (-NOT $isserver )
        {
            #Disable defender until next reboot
            Set-MpPreference -DisableRealtimeMonitoring $true 
            #update the windows store
            Update-StoreApps
        }


        #install the media pack on Windows 10 N machines, and the media features on Windows Server
        Install-MediaFeatures

     
  
        #check if Windows Update is configured for Application Updates (Microsoft updates)
        Configure-MSUpdate
     
     
        ##install Windows Updates
        $cmd = Join-Path (Get-ScriptPath) Get-WindowsUpdates.ps1
        &($cmd) -Install -EulaAccept -verbose


        #run the script at next startup
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "myScript" -value ('powershell -ExecutionPolicy bypass -f "' + (Join-Path (Get-ScriptPath) $MyInvocation.MyCommand.Name ) + '"')
           
        #set UAC off.
        if (-not $isServer)
        {
            Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0
        }
        
        #set registry entries to automatically log on 5 times
        Set-AutoLogon -loginName '.\afi' -password 'afi12345!' -count 5 
        
      
        "2">($stepFile)

        ##reboot
        Restart-Computer 
        break
    }
    2
    {
        Show-Warning

        #Disable Windows Defender
        if (-NOT $isserver -and $OsVersion -eq 10)
        {
            Set-MpPreference -DisableRealtimeMonitoring $true     
        }


        "Installing French Language Pack (15 min)"
        #install frenchLanguagePack
        Install-FrenchLanguagePack
    
    
        "Installing French Keyboards and dictionaries (1 min)"
        Install-FrenchKeyboardsAndDictionaries
    
        #http://www.michelstevelmans.com/multiple-languages-regional-options-keyboard-layouts-citrix-appsense/
    

        "Setting the language and keyboard to the right ones"

        #il y a trois fichiers: 
        #en-US.xml affiche en anglais, avec le clavier canadien Francais (Windows 8.1, windows 10, Windows Server)
        #fr-FR.xml affiche en francais, avec le clavier Canadien (windows 8.1, Windows Server 2012R2)
        #fr-CA.xml affiche en francais-Ca, avec le clavier Canadien (windows 10, Windows Server 2016)
        Set-LanguageAndKeyboard "en-US.xml"


        "Installing updates (part 2)"
        ##install Windows Updates
        $cmd = Join-Path (Get-ScriptPath) Get-WindowsUpdates.ps1
        &($cmd) -Install -EulaAccept -verbose
       

        "3" > $stepFile

        ##reboot
        Restart-Computer 
        break
   }
   3
   {
       
        Show-Warning

        #Disable Windows Defender
        if (-NOT $isserver -and $OsVersion -eq 10)
        {
             
           Set-MpPreference -DisableRealtimeMonitoring $true     
        }

        "Installing VS2015 stuff"

        #get the visual Studio setup File_Path
        $vsSetup = Get-VsSetupPath


        #Get the visual Studio Product name (community, professional, enterprise)
        if ($vsSetup -match 'vs_(\w+).exe')  
        { 
            $vsProduct =  $Matches[1]
        }; 

  
        #activate VS2015
        switch ($vsProduct) {
          "professional"  {
            #Activate Vs2015 (07060 = Enterprise, 07062=Pro)
            &"C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\StorePID.exe"  HMGNV-WCYXV-X7G9W-YCX63-B98R2 07062
            break
          }
          "enterprise" {
            &"C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\StorePID.exe"  2XNFG-KFHR8-QV3CP-3W6HT-683CH 07060 
            break
          }
        }


        #Activate Vs2015 (07060 = Enterprise, 07062=Pro)
        #  2XNFG-KFHR8-QV3CP-3W6HT-683CH 07060 
        #  HM6NR-QXX7C-DFW2Y-8B82K-WTYJV 07060 
        #  HMGNV-WCYXV-X7G9W-YCX63-B98R2 07062 

        
        
        #start IE for the first-time (useful for later scripts)
        Initialize-IE
         
        #get Nuget  (TODO: this will fail when the new version of nuget comes along. We need something better.)
        Install-VSExtension "https://visualstudiogallery.msdn.microsoft.com/5d345edc-2e2d-4a9c-b73b-d53956dc458d/file/146283/7/NuGet.Tools.vsix"

        #get "microsoft Azure Storage Connected Service"
        Install-VSExtension "https://visualstudiogallery.msdn.microsoft.com/c5f89a45-6549-4081-96dc-a76a461560bc/file/169224/2/Microsoft.VisualStudio.ConnectedServices.Azure.Storage.vsix" 
                
    
        #get ssdt july 2015  (TODO: this will fail when the new version of ssdt comes along. We need something better.   
        Download-File "http://download.microsoft.com/download/4/D/3/4D39DA54-DF09-4628-B63D-685BFCE523EA/Dev14/EN/SSDTSetup.exe" `
                       ( $dl + "SSDTSetup.exe" )
   

        #get preview ssdt august 2015  (TODO: this will fail when the new version of ssdt comes along. We need something better.)
    
        #  Download-File "http://download.microsoft.com/download/C/B/D/CBD43835-E41E-4A4C-B040-664B8E6FB5B7/EN/SSDTSetup.exe" `
        #                ( $dl + "SSDTSetup.exe" ) 
        Start-Process  ($dl + "SSDTSetup.exe") -ArgumentList ('/passive /promptrestart')  -Wait 


        #Download WebPI
        Download-File "http://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi" `
                     ($dl + "WebPlatformInstaller_amd64_en-US.msi")
        #Install WebPI
        Start-Process "msiexec" -ArgumentList ('/passive /i "' + $dl  + 'WebPlatformInstaller_amd64_en-US.msi"')  -Wait 
        
        #Install Vs2015AzurePack
        Start-Process  ($env:ProgramFiles + "\Microsoft\Web Platform Installer\WebpiCmd.exe") -ArgumentList ('/install /products:Vs2015AzurePack /log:"' + $env:USERPROFILE  + '\downloads\azure.log" /AcceptEula') -wait
        
        #Install TypeScript
        Start-process $vssetup  -ArgumentList '/passive /installselectableitems TypeScript' -wait
        Start-process $vssetup  -ArgumentList '/passive /installselectableitems TypeScriptV2' -wait

        #Install Windows SDK 1.1
        if(-not $isServer -and $OsVersion -eq 10)
        {
            Start-process $vssetup  -ArgumentList '/passive /AlternateResources WindowsExpress /Modify /InstallSelectableItems Windows10_ToolsAndSDK' -wait
        }

      
        #Install Apache cordova tooling
        if(-not $isServer)
        {
            Start-process $vssetup  -ArgumentList '/passive  /installselectableitems MDDJSCore' -wait
        }
        
        "Install Keyboard"  
        Set-LanguageAndKeyboard "en-US.xml"    
          
  
        "Install Browsers"
        $cmd = Join-Path (Get-ScriptPath) get-browsers.ps1
        & $cmd      
        $cmd = Join-Path (Get-ScriptPath) chrome.cmd
        & $cmd      
        $cmd = Join-Path (Get-ScriptPath) firefox.cmd
        & $cmd      
        $cmd = Join-Path (Get-ScriptPath) opera.cmd
        & $cmd      
          
  
        "install Taskbar shortcut"
        #does not work beacause of a bug in windows 10
        $shell = new-object -com "Shell.Application"  
        $folder = $shell.Namespace((Join-Path ${env:ProgramFiles(x86)} Google\Chrome\Application ))
        $item = $folder.Parsename('chrome.exe')
        $item.invokeverb('taskbarpin');
       
        $folder = $shell.Namespace((Join-Path ${env:ProgramFiles(x86)} "Mozilla Firefox" ))
        $item = $folder.Parsename('firefox.exe')
        $item.invokeverb('taskbarpin');
    
        $folder = $shell.Namespace((Join-Path ${env:ProgramFiles(x86)} "Opera" ))
        $item = $folder.Parsename('launcher.exe')
        $item.invokeverb('taskbarpin');
 
        $folder = $shell.Namespace((Join-Path ${env:ProgramFiles} "Internet Explorer" ))
        $item = $folder.Parsename("iexplore.exe")
        $item.invokeverb('taskbarpin');

        $folder = $shell.Namespace((Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio 14.0\Common7\IDE" ))
        $item = $folder.Parsename('devenv.exe')
        $item.invokeverb('taskbarpin');

        $shell=$null

        "Initialize Visual Studio"
        Initialize-VisualStudio
          
        "Reenable UAC "              
        if (-not $isServer)
        {
            Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 1
        }
 
        "Reenable Windows Defender"
        Set-MpPreference -DisableRealtimeMonitoring $false
      
        "Reenable Execution Policy"
        Set-ExecutionPolicy Unrestricted    
     
        "6">($stepFile) 
        "Étape 5 terminée"

        Restart-Computer 
        break  
    }
    6
    {   
        Show-Warning

        "Remove Script"
        Remove-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "myScript"

        if (-NOT $isserver )
        { 
            #update the windows store
            Update-StoreApps
        }
    
        "Etapes terminees.  C'est fini!" 
        "7">($stepFile) 
        break   
    }
    7
    {

         "8">($stepFile) 
        "Étape 7 terminé"
      
        break  
    }
}





