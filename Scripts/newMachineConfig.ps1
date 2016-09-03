
$dl=$env:USERPROFILE + "\downloads\"
$stepFile=$dl + "step.txt"


If (!(Test-Path $stepFile)){
   "1">$stepFile
}

$step=(get-content $stepfile)

$BuildVersion=[Environment]::OSVersion.Version.Build
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
    #return "c:\scripts"
    return "C:\demo\AfiSetup\Scripts"
  }

}


function Update-StoreApps
{      

    Add-Type -AssemblyName System.Windows.Forms

    start ms-windows-store:updates 
    start-sleep -Milliseconds 4000
    [System.Windows.Forms.SendKeys]::SendWait("~")
    start-sleep -Milliseconds 8000
    [System.Windows.Forms.SendKeys]::SendWait("{TAB}~")
    start-sleep -Milliseconds 8000
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
    start-sleep -Milliseconds 3000
}

function Disable-IEESC
{
    $AdminKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
    $UserKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
    Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
    Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0

    Rundll32 iesetup.dll, IEHardenLMSettings
    Rundll32 iesetup.dll, IEHardenUser
    Rundll32 iesetup.dll, IEHardenAdmin
    Rundll32 iesetup.dll, IEHardenMachineNow

    start-sleep 3

    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "First Home Page" -Value "http://www.google.ca/"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "Start Page" -Value "http://www.google.ca/"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Internet Explorer\Main" -Name "Default_Page_URL" -Value "http://www.google.ca/"
}

function Install-MediaFeatures
{
#detect windows version for client
    if (-NOT $isserver)
    {
        $HasMedia='disabled'
        $HasMedia=(Get-WindowsOptionalFeature -online -FeatureName MediaPlayback).State


        #detect if windows media playback is not installed
        if ($HasMedia -ne 'Enabled' -and $OsVersion -eq 10 )
        {
            $url="https://download.microsoft.com/download/1/3/F/13F19BF0-17CF-4D0F-938C-41D0489C3FE6/KB3133719-x64.msu.msu"

            
            if ($BuildVersion -lt 14393) 
            {
               $url="https://download.microsoft.com/download/B/E/3/BE302763-5BFD-4209-9C98-02DF5B2DB452/KB3099229_x64.msu"
            }
           
            if ($BuildVersion -lt 10586) 
            {
               $url="http://download.microsoft.com/download/7/F/2/7F2E00A7-F071-41CA-A35B-00DC536D4227/Windows10-KB3010081-x64.msu"
            }
            
            "Downloading Media Pack...."
            #Download Media feature pack
            Download-file $url  ( $dl + "Win-Media-Pack.msu") 
                
            "Installing Media Pack"
            #install Media feature pack
            $wusaArgs =  '"' + $dl + 'Win-Media-Pack.msu" /quiet /norestart'
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

    if (-NOT $isserver -and $OsVersion -eq 10 )   
    {             
        $LanguagePackSource = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2016/07/lp_a63abaa1136ce9bd7a50ae1eaf54f1a58500c1a7.cab"
            
        if ($BuildVersion -lt 14393) 
        {
            $LanguagePackSource = "http://download.windowsupdate.com/d/msdownload/update/software/updt/2015/11/lp_7f834b68030b2e216d529c565305ea0ee8bb2489.cab"
        }
       
        if ($BuildVersion -lt 10586)
        {
            $LanguagePackSource = "http://download.windowsupdate.com/d/msdownload/update/software/updt/2015/07/lp_8f6e1d4cb3972edef76030b917020b7ee6cf6582.cab"
        }
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
        add-WindowsCapability -online -name Language.Speech~~~fr-CA~0.0.1.0
        add-WindowsCapability -online -name Language.TextToSpeech~~~fr-CA~0.0.1.0
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



    #$confPath= Join-Path "C:\demo"  "en-US.xml"
    $confPath = Join-Path (Get-ScriptPath) $fileName
    $arguments = 'intl.cpl,, /f:"' + $confPath + '"'
    Start-Process control.exe -ArgumentList ($arguments)     
}

#Get VS Setup filepath exe  (ex: Vs_enterprise.exe or vs_community.exe) 
function Get-VsSetupPath
{
    $result = Get-ChildItem -ErrorAction Ignore -Path "C:\ProgramData\Package Cache\" -Name "vs_*.exe" -Exclude @("vs_*[psk].exe","vs_intshell*","vs_isoshell*")  -Recurse
    if ($result -eq $null) 
    {
       return $null
    } else
    {
        return  get-ChildItem -Path  (join-path "C:\ProgramData\Package Cache\" $result ) 
    }
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




function Change-ProcessName
{
 param 
    (
        [parameter(position=1,mandatory=$true)] $appName
    )  

         $code = @'
            static string originalImagePathName;
            static int unicodeSize = IntPtr.Size * 2;
 
            static void GetPointers(out IntPtr imageOffset, out IntPtr imageBuffer)
            {
                IntPtr pebBaseAddress = GetBasicInformation().PebBaseAddress;
                var processParameters = Marshal.ReadIntPtr(pebBaseAddress, 4 * IntPtr.Size);
                imageOffset = Increment(processParameters,4 * 4 + 5 * IntPtr.Size + unicodeSize + IntPtr.Size + unicodeSize);
                imageBuffer = Marshal.ReadIntPtr(imageOffset, IntPtr.Size);
            }
 
            public static void ChangeImagePathName(string newFileName)
            {
                IntPtr imageOffset, imageBuffer;
                GetPointers(out imageOffset, out imageBuffer);
 
                //Read original data
                var imageLen = Marshal.ReadInt16(imageOffset);
                originalImagePathName = Marshal.PtrToStringUni(imageBuffer, imageLen / 2);
 
                var newImagePathName = Path.Combine(Path.GetDirectoryName(originalImagePathName), newFileName);
                if (newImagePathName.Length > originalImagePathName.Length) throw new Exception("new ImagePathName cannot be longer than the original one");
 
                //Write the string, char by char
                var ptr = imageBuffer;
                foreach(var unicodeChar in newImagePathName)
                {
                    Marshal.WriteInt16(ptr, unicodeChar);
                    ptr = Increment(ptr,2);
                }
                Marshal.WriteInt16(ptr, 0);
 
                //Write the new length
                Marshal.WriteInt16(imageOffset, (short) (newImagePathName.Length * 2));
            }
 
            public static void RestoreImagePathName()
            {
                IntPtr imageOffset, ptr;
                GetPointers(out imageOffset, out ptr);
 
                foreach (var unicodeChar in originalImagePathName)
                {
                    Marshal.WriteInt16(ptr, unicodeChar);
                    ptr = Increment(ptr,2);
                }
                Marshal.WriteInt16(ptr, 0);
                Marshal.WriteInt16(imageOffset, (short)(originalImagePathName.Length * 2));
            }
 
            public static ProcessBasicInformation GetBasicInformation()
            {
                uint status;
                ProcessBasicInformation pbi;
                int retLen;
                var handle = System.Diagnostics.Process.GetCurrentProcess().Handle;
                if ((status = NtQueryInformationProcess(handle, 0,
                    out pbi, Marshal.SizeOf(typeof(ProcessBasicInformation)), out retLen)) >= 0xc0000000)
                    throw new Exception("Windows exception. status=" + status);
                return pbi;
            }
 
            [DllImport("ntdll.dll")]
            public static extern uint NtQueryInformationProcess(
                [In] IntPtr ProcessHandle,
                [In] int ProcessInformationClass,
                [Out] out ProcessBasicInformation ProcessInformation,
                [In] int ProcessInformationLength,
                [Out] [Optional] out int ReturnLength
                );
 
            public static IntPtr Increment(IntPtr ptr, int value)
            {
                unchecked
                {
                    if (IntPtr.Size == sizeof(Int32))
                        return new IntPtr(ptr.ToInt32() + value);
                    else
                        return new IntPtr(ptr.ToInt64() + value);
                }
            }
 
            [StructLayout(LayoutKind.Sequential)]
            public struct ProcessBasicInformation
            {
                public uint ExitStatus;
                public IntPtr PebBaseAddress;
                public IntPtr AffinityMask;
                public int BasePriority;
                public IntPtr UniqueProcessId;
                public IntPtr InheritedFromUniqueProcessId;
            }
'@

        add-type -Namespace Win32 -Name ImageProcess -UsingNamespace System.IO -MemberDefinition  $code

        [Win32.ImageProcess]::ChangeImagePathName($appName);
}



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
    start-sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait($appname) # type app name 
    start-sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait("+{F10}")  # Shift-F10 to call right-click menu
    start-sleep -Milliseconds 400
    [System.Windows.Forms.SendKeys]::SendWait("{DOWN}{DOWN}{DOWN}{DOWN}") # down 4 times,
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}") # enter
    [System.Windows.Forms.SendKeys]::SendWait("{ESC}") # escape
    start-sleep -Milliseconds 200
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

    if (Test-Path "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\devenv.exe")
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
        until ($proc[0].HasExited)
    }
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
        Set-Background "red"

       "installation du poste"
        #Disable the script execution policy for future scripts that are running 
        Set-ExecutionPolicy bypass -Scope LocalMachine -Force
        #Set-ExecutionPolicy bypass -Scope CurrentUser
        #Get-ExecutionPolicy -List
    
        #Show hidden Files
        Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt "0"

        #Put right time zone
        tzutil /s "Eastern Standard Time"

        #run the script at next startup
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "myScript" -value ('powershell -ExecutionPolicy bypass -f "' + (Join-Path (Get-ScriptPath) $MyInvocation.MyCommand.Name ) + '"')
           
        #set UAC off.
        if (-not $isServer)
        {
            Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0
        }
        
        #set registry entries to automatically log on 5 times
        Set-AutoLogon -loginName '.\afi' -password 'afi12345678!' -count 5 


        #If windows client
        if (-NOT $isserver )
        {
            #Disable defender until next reboot
            Set-MpPreference -DisableRealtimeMonitoring $true 
            #update the windows store
          #  Update-StoreApps
        }


        #install the media pack on Windows 10 N machines, and the media features on Windows Server
        Install-MediaFeatures

     
  
        #check if Windows Update is configured for Application Updates (Microsoft updates)
        Configure-MSUpdate
     
     
        ##install Windows Updates
        $cmd = Join-Path (Get-ScriptPath) Get-WindowsUpdates.ps1
        &($cmd) -Install -EulaAccept -verbose
        

      
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
        $vsSetup = (Get-VsSetupPath).FullName


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
        #  WXN74-VRMXH-J8X3H-M8F7W-CPQB8  community?

        
        
        #start IE for the first-time (useful for later scripts)
        Initialize-IE
                

        #if not null
        if (Get-VsSetupPath) { 
        "visual studio detected"   >> ($dl + "tests.txt")
        "visual studio detected" 
           
        #download French VS Language pack
        Download-File "https://download.microsoft.com/download/5/8/F/58F2ADD0-CE37-4377-9D50-269552FE061A/vs_langpack.exe" `
                   ($dl + "vs_langpack.exe")

        #install French VS Language pack
        Start-Process  ($dl + "vs_langpack.exe") -ArgumentList ('  /passive /promptrestart ')  -Wait 


        #Download WebPI
        Download-File "http://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi" `
                     ($dl + "WebPlatformInstaller_amd64_en-US.msi")
        #Install WebPI
        Start-Process "msiexec" -ArgumentList ('/passive /i "' + $dl  + 'WebPlatformInstaller_amd64_en-US.msi"')  -Wait 
        

        #Download fix for update3
        Download-File "http://download.microsoft.com/download/7/f/5/7f5dadbd-c2da-4c0e-b2c7-0facadce633d/vs14-kb3165756.exe" `
                     ($dl + "vs14-kb3165756.exe")
        
        #install fix for update3
        Start-Process  ($dl + "vs14-kb3165756.exe") -ArgumentList ('/passive /promptrestart')  -Wait 

      

        #download asp.net tooling preview 2
        Download-File "https://visualstudiogallery.msdn.microsoft.com/c94a02e9-f2e9-4bad-a952-a63a967e3935/file/77371/10/DotNetCore.1.0.0-VS2015Tools.Preview2.0.1.exe" `
                   ($dl + "DotNetCore.1.0.0-VS2015Tools.Preview2.0.1.exe")

        #install asp.net tooling preview 2
        Start-Process  ($dl + "DotNetCore.1.0.0-VS2015Tools.Preview2.0.1.exe") -ArgumentList ('  /passive /promptrestart ')  -Wait 


        #download ssdt
        Download-File "https://go.microsoft.com/fwlink/?LinkID=824659&clcid=0x409" `
                   ($dl + "SSDTSetup.exe")

        #install ssdt
        Start-Process  ($dl + "SSDTSetup.exe") -ArgumentList ('INSTALLALL=1  /passive /promptrestart')  -Wait 


        #Download vsCode
        Download-File "https://go.microsoft.com/fwlink/?LinkID=623230" `
                   ($dl + "VSCodeSetup-stable.exe")

        #install vscode
        Start-Process  ($dl + "VSCodeSetup-stable.exe") -ArgumentList ('  /silent /tasks="desktopicon,associatewithfiles,addtopath" ') -Wait 

        #remove last one ="desktopicon,associatewithfiles,addtopath,runcode"


        #Install Vs2015AzurePack
     ##   Start-Process  ($env:ProgramFiles + "\Microsoft\Web Platform Installer\WebpiCmd.exe") -ArgumentList ('/install /products:Vs2015AzurePack /log:"' + $env:USERPROFILE  + '\downloads\azure.log" /AcceptEula') -wait
        

        #Install TypeScript, git for windows, github VS
     ##   Start-process $vssetup  -ArgumentList '/passive /installselectableitems TypeScript;GitForWindows;GitHubVS;PowerShellTools' -wait


        #Install Apache cordova tooling (includes windows sdk 1.1, ant, git for windows, nodejs, android emulator, web socket and web tools)
     ##   if(-not $isServer)
     ##   {
     ##       Start-process $vssetup  -ArgumentList '/passive  /installselectableitems MDDJSCore' -wait
     ##   }

     }  else {
    
             "visual studio NOT detected"   >> ($dl + "tests.txt")
        "visual studio NOT detected" 
     
        #download ssdt
        Download-File "https://go.microsoft.com/fwlink/?LinkID=824659&clcid=0x409" `
                   ($dl + "SSDTSetup.exe")

        #install ssdt
        #Start-Process  ($dl + "SSDTSetup.exe") -ArgumentList ('INSTALLALL=1  /passive /promptrestart')  -Wait 


        #Download vsCode
        Download-File "https://go.microsoft.com/fwlink/?LinkID=623230" `
                   ($dl + "VSCodeSetup-stable.exe")

        #install vscode
        Start-Process  ($dl + "VSCodeSetup-stable.exe") -ArgumentList ('  /silent /tasks="desktopicon,associatewithfiles,addtopath" ') -Wait 

        #remove last one ="desktopicon,associatewithfiles,addtopath,runcode"

     
     }
        
        "Install Keyboard"  
        Set-LanguageAndKeyboard "en-US.xml"    
          

        "Install Browsers"
        $cmd = Join-Path (Get-ScriptPath) get-browsers.ps1
        & $cmd $dl  
        $cmd = Join-Path (Get-ScriptPath) chrome.cmd
        & $cmd $dl.Trimend('\')
        $cmd = Join-Path (Get-ScriptPath) firefox.cmd
        & $cmd $dl.Trimend('\')
        $cmd = Join-Path (Get-ScriptPath) opera.cmd
        & $cmd $dl.Trimend('\')
 

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
        Set-ExecutionPolicy Unrestricted  -Scope LocalMachine -Force  
     
        "4">($stepFile) 
        "Étape 3 terminée"

        Restart-Computer 
        break  
    }
    4
    {   
        Show-Warning

        "Remove Script"
        Remove-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "myScript"

        if (-NOT $isserver )
        { 
            "Update the windows store"
            Update-StoreApps
        }

        if ($OsVersion -eq 10)
        {
           Change-ProcessName("explorer.exe")
        }

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
        

        Set-Background "restore"
    
        "Etapes terminees.  C'est fini!" 
        "5">($stepFile) 
        break   
    }
    5
    {

         "6">($stepFile) 
        "Étape 5 terminé"
      
        break  
    }
}





