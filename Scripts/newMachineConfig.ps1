
$dl=$env:USERPROFILE + "\downloads\"
$stepFile=$dl + "step.txt"


If (!(Test-Path $stepFile)){
   "1">$stepFile
}

$step=(get-content $stepfile)

$OsVersion=[Environment]::OSVersion.Version.Major 
$isServer= (Gwmi  Win32_OperatingSystem).productType -gt 1

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


       "installation du poste"
        Set-ExecutionPolicy bypass
    
        #Show hidden Files
        Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt "0"

        #Put right time zone
        tzutil /s "Eastern Standard Time"

       

        if (-NOT $isserver -and $OsVersion -eq 10)
        {      
           Set-MpPreference -DisableRealtimeMonitoring $true 
           Add-Type -AssemblyName System.Windows.Forms

           start ms-windows-store:updates 
           start-sleep -Milliseconds 4000
           [System.Windows.Forms.SendKeys]::SendWait("~")
           start-sleep -Milliseconds 6000
           [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
        }

    
        #detect windows version for client
        if ((gwmi win32_operatingsystem).producttype -eq 1)
        {
           $HasMedia='disabled'
           $HasMedia=(Get-WindowsOptionalFeature -online -FeatureName MediaPlayback).State


           #detect if windows media playback is not installed
           if ($HasMedia -ne 'Enabled')
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


            function Disable-IEESC{
              $AdminKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
              $UserKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
              Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
              Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0
            }
            Disable-IEESC
           
            Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced TaskBarSizeMove "0"
            Stop-Process -Name Explorer
   
        }

  
        #check if Windows Update is configured for Application Updates (Microsoft updates)
        $ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
        $ServiceManager.ClientApplicationID = "My App"
        $status=$ServiceManager.QueryServiceRegistration("7971f918-a847-4430-9279-4a52d1efe18d").RegistrationState
        if ($status -lt 3)
        {
           $ServiceManager.AddService2( "7971f918-a847-4430-9279-4a52d1efe18d",7,"")
        }
     
     
        ##install Windows Updates
        $cmd = Join-Path (split-path $MyInvocation.invocationname) Get-WindowsUpdates.ps1
        &($cmd) -Install -EulaAccept -verbose



        #set registry entries to automatically log on
        Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "myScript" -value ('powershell -ExecutionPolicy bypass -f "' +   $MyInvocation.InvocationName  + '"')
        
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName  -Value ".\Afi" 
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword  -Value "afi12345!" 
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 5 
        
        #set UAC off.
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0

        "2">($stepFile)

        ##reboot
        Restart-Computer 
        break
   }
   2
   {

      "Installing French Language"


       $LanguagePackSource=""

       if (-NOT $isserver -and $OsVersion -eq 10)
        {
             
           Set-MpPreference -DisableRealtimeMonitoring $true     
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
        
       $frCA=$dl + "fr-ca.cab"

      
       Download-file $LanguagePackSource $frCA 
      
    
       Add-WindowsPackage -Online -PackagePath ($frCA)


       if (-NOT $isserver -and $OsVersion -eq 10)
        {      
   
            #http://www.michelstevelmans.com/multiple-languages-regional-options-keyboard-layouts-citrix-appsense/
            #Get-WindowsCapability -online
            #add-WindowsCapability -online -name Language.Basic~~~fr-FR~0.0.1.0
            add-WindowsCapability -online -name Language.Basic~~~fr-CA~0.0.1.0
            add-WindowsCapability -online -name Language.OCR~~~fr-CA~0.0.1.0


            $lang=Get-WinUserLanguageList 
            #$lang.insert(0, "fr-CA")
            $lang.add("fr-CA")
            Set-WinUserLanguageList $lang -force
        } elseif ( $OsVersion -lt 10)
        {      
            $lang=Get-WinUserLanguageList 
            #$lang.insert(0, "fr-CA")
            $lang.add("fr-CA")
            Set-WinUserLanguageList $lang -force
        }

         Start-Process control.exe -ArgumentList 'intl.cpl,, /f:"c:\scripts\en-US.xml"'     



        "Installing updates (part 2)"
        ##install Windows Updates
        $cmd = Join-Path (split-path $MyInvocation.invocationname) Get-WindowsUpdates.ps1
        &($cmd) -Install -EulaAccept -verbose
        "over"

        "3" > $stepFile

        ##reboot
        Restart-Computer 
        break
   }
   3
   {
        "Installing VS2015 stuff"
        
       if (-NOT $isserver -and $OsVersion -eq 10)
        {
             
           Set-MpPreference -DisableRealtimeMonitoring $true     
        }

        #Get VS Setup filepath exe  (ex: Vs_enterprise.exe or vs_community.exe) 
        $result = dir -Path "C:\ProgramData\Package Cache\" -Name "vs_*.exe" -Exclude "vs_*[ps].exe" -Recurse
        if ($result -match 'vs_(\w+).exe')  { $vsProduct =  $Matches[1]}; 
        $vssetup =  ("C:\ProgramData\Package Cache\" + $result)

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




        #get Nuget  (TODO: this will fail when the new version of nuget comes along. We need something better.)
        Download-File  "https://visualstudiogallery.msdn.microsoft.com/5d345edc-2e2d-4a9c-b73b-d53956dc458d/file/146283/7/NuGet.Tools.vsix" `
                        ($dl + "NuGet.Tools.vsix") 
 
        #install Nuget
        Start-Process "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\vsixinstaller.exe" -ArgumentList ('-q "' + $dl  + 'NuGet.Tools.vsix"')  -Wait 



     md 'HKLM:\Software\Policies\Microsoft\Internet Explorer'
     md 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Main'
     New-ItemProperty -path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -name "DisableFirstRunCustomize" -value 1
        "5a">($stepFile)
     Add-Type -AssemblyName System.Windows.Forms
     Add-Type -AssemblyName Microsoft.VisualBasic

     Start-Process 'C:\Program Files (x86)\Internet Explorer\iexplore.exe'  
     start-sleep -Milliseconds 5000
           "5b">($stepFile)
  
     $proc=get-process -Name iexplore
     
    # [Microsoft.VisualBasic.Interaction]::AppActivate($proc[0].id)
    start-sleep -Milliseconds 1000
    [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
          "5c">($stepFile)


        #get "microsoft Azure Storage Connected Service"
        Download-File "https://visualstudiogallery.msdn.microsoft.com/c5f89a45-6549-4081-96dc-a76a461560bc/file/169224/2/Microsoft.VisualStudio.ConnectedServices.Azure.Storage.vsix" `
                  ($dl + "Microsoft.VisualStudio.ConnectedServices.Azure.Storage.vsix")

        #get "microsoft Azure Storage Connected Service"
        Start-Process "C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\vsixinstaller.exe" -ArgumentList ('-q "' +  $dl + 'Microsoft.VisualStudio.ConnectedServices.Azure.Storage.vsix"')  -Wait 



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
        
        #Installer Vs2015AzurePack
        Start-Process  ($env:ProgramFiles + "\Microsoft\Web Platform Installer\WebpiCmd.exe") -ArgumentList ('/install /products:Vs2015AzurePack /log:"' + $env:USERPROFILE  + '\documents\azure.log" /AcceptEula') -wait


        
        #Install TypeScript
        Start-process $vssetup  -ArgumentList '/passive  /installselectableitems TypeScriptV2' -wait
        Start-process $vssetup  -ArgumentList '/passive  /installselectableitems TypeScript /ChainingPackage VSNotificationHub' -wait


       "4">($stepFile)
       "Etape 3 terminée"
       #Install the right keyboards.
       Start-Process control.exe -ArgumentList 'intl.cpl,, /f:"c:\scripts\en-US.xml"'     

     "5">($stepFile)  
    "Etape 4 terminée"
                   
  
     $cmd = Join-Path (split-path $MyInvocation.invocationName) get-browsers.ps1
     & $cmd      
     $cmd = Join-Path (split-path $MyInvocation.invocationName) chrome.cmd
     & $cmd      
     $cmd = Join-Path (split-path $MyInvocation.invocationName) firefox.cmd
     & $cmd      
     $cmd = Join-Path (split-path $MyInvocation.invocationName) opera.cmd
     & $cmd      
           "5d">($stepFile)
  

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

          "5e">($stepFile)
  
  
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
        "5g">($stepFile)
  
     }
     until ($proc.HasExited)
     "5h">($stepFile)
                       
     if (-not $isServer)
     {
        Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 1
           "5i">($stepFile)  
     }
 
       "5j">($stepFile)
  
     Set-MpPreference -DisableRealtimeMonitoring $false
           "5k">($stepFile)
  
     Set-ExecutionPolicy Unrestricted
 #    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 0    
 #   Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword  
      
     
     "6">($stepFile) 
     "Étape 5 terminée"

     Restart-Computer 
     break  
   }
   6
   {   

     Remove-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -name "myScript"


     $isServer= (Gwmi  Win32_OperatingSystem).productType -gt 1
     if (-not $isServer)
     {
       Add-Type -AssemblyName System.Windows.Forms

       start ms-windows-store:updates 
       start-sleep -Milliseconds 4000
       [System.Windows.Forms.SendKeys]::SendWait("~")
       start-sleep -Milliseconds 3000
       [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
     }


       "Etapes terminees.  C'est fini!" 
       break   
   }
   7
   {
      "7">($stepFile) 
     "Étape 7 terminé"
      
     break  
   }
}

