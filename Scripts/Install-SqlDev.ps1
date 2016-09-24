
$dl=$env:USERPROFILE + "\downloads\"

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


$sourceSqlDev = "https://download.microsoft.com/download/E/1/2/E12B3655-D817-49BA-B934-CEB9DAC0BAF3/SQLServer2016-x64-ENU-Dev.iso";
$SqlDev= ($dl + "SQLServer2016-x64-ENU-Dev.iso")

if (-Not (Test-Path $SqlDev)) {
   Download-File $sourceSqlDev $SqlDev
}


$drv=((Mount-DiskImage $SqlDev -PassThru  | Get-Volume).DriveLetter + ':\')


if ($true)
{

$user = $(whoami)

& ($drv + 'setup.exe') /qs `
                       /Action=install `
                       /IAcceptSqlServerLicenseTerms `
                       /Features=sql `
                       /InstanceName=MSSQLSERVER `
                       /SqlSvcAccount="NT SERVICE\MSSQLSERVER" `
                       /SqlSysAdminAccounts="$user" `
                       /AgtSvcAccount="NT SERVICE\SQLSERVERAGENT" `
                       /SqlSvcInstantFileInit="True" | Out-Null

}


#--------------------------------------------------------


$sourcessms="http://go.microsoft.com/fwlink/?LinkID=824938"
$ssms= ($dl + "SSMS-setup-enu.exe")

if (-Not (Test-Path $ssms)) {
   Download-File $sourcessms $ssms
}

& ($ssms) /install /passive | Out-Null


#--------------------------------------------------------


$sourceSsdt="https://go.microsoft.com/fwlink/?LinkID=824659&clcid=0x409"
$ssdt= ($dl + "SSDTSetup.exe")

if (-Not (Test-Path $ssdt)) {
   Download-File $sourceSsdt $ssdt
}

& ($ssdt) installall=1 /passive | Out-Null












if ($false)
{
& ($drv + 'setup.exe') /qs `
                       /Action=uninstall `
                       /IAcceptSqlServerLicenseTerms `
                       /Features=SQL,AS,RS,IS,DQC,MDS,SQL_SHARED_MR,Tools `
                       /InstanceName=MSSQLSERVER | Out-Null

$ssms= ($dl + "SSMS-setup-enu.exe")
& ($ssms) /uninstall /passive | Out-Null

$ssdt= ($dl + "SSDTSetup.exe")
& ($ssdt) /uninstall /passive | Out-Null



(Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*) | `
 Select-Object DisplayName, UninstallString | `
 ? DisplayName -like "*sql server*" | `
 % -Process { $items = ($_.UninstallString.split(" ",2)); 
                        $items[1]= $items[1].Replace("/I","/x")  ;   
                        & ($items[0]) $items[1] /passive | Out-Null; }

 
(Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*) | `
 Select-Object DisplayName, UninstallString | `
 Where-Object DisplayName -like "*sql server*" | `
 % -Process { $items = ($_.UninstallString.split(" ",2)); 
                        $items[1]= $items[1].Replace("/I","/x")  ;   
                        & ($items[0]) $items[1] /passive | Out-Null; }


 
 
(Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*) | `
 Select-Object DisplayName, UninstallString | `
 ? DisplayName -like "Microsoft Visual C++ 2010*Redistributable*" | `
 % -Process {  $unstr=$_.UninstallString.Replace("\Package Cache\","\Package_Cache\" ).Replace("  "," ") ;
               $items = ($unstr.split(" ",2));
                        $items[0]= $items[0].Replace("\Package_Cache\","\Package Cache\" ).Replace("`"", "") ;
                        $items[1]= $items[1].Replace("/I","/x"); 
                        & ($items[0]) $items[1] /passive| Out-Null; 
                        }
 
 (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*) | `
 Select-Object DisplayName, UninstallString | `
 ? DisplayName -like "Microsoft Visual C++ 2010*Redistributable*" | `
 % -Process {  $unstr=$_.UninstallString.Replace("\Package Cache\","\Package_Cache\" ).Replace("  "," ") ;
               $items = ($unstr.split(" ",2));
                        $items[0]= $items[0].Replace("\Package_Cache\","\Package Cache\" ).Replace("`"", "") ;
                        $items[1]= $items[1].Replace("/I","/x"); 
                        & ($items[0]) $items[1] /passive| Out-Null; 
                        }
                


 }

#Start-Process  "msiexec"  -argumentlist "/passive /i ""$SqlLocalDb"" IACCEPTSQLLOCALDBLICENSETERMS=YES" -Wait 
#Start-Process  "msiexec"  -argumentlist "/passive /i ""$odbc"" IACCEPTMSODBCSQLLICENSETERMS=YES" -Wait 
#Start-Process  "msiexec"  -argumentlist "/passive /i ""$CmdLineUtil"" IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES" -Wait 


