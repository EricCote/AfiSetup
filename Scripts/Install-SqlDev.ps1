
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

& ($drv + 'setup.exe') /qs `
                       /Action=install `
                       /IAcceptSqlServerLicenseTerms `
                       /Features=sql `
                       /InstanceName=MSSQLSERVER `
                       /SqlSvcAccount="NT SERVICE\MSSQLSERVER" `
                       /SqlSysAdminAccounts="win10b\afi" `
                       /AgtSvcAccount="NT SERVICE\SQLSERVERAGENT" `
                       /SqlSvcInstantFileInit="True" | Out-Null

if ($false)
{
& ($drv + 'setup.exe') /qs `
                       /Action=uninstall `
                       /IAcceptSqlServerLicenseTerms `
                       /Features=SQL,AS,RS,IS,DQC,MDS,SQL_SHARED_MR,Tools `
                       /InstanceName=MSSQLSERVER | Out-Null
 }               



#Start-Process  "msiexec"  -argumentlist "/passive /i ""$SqlLocalDb"" IACCEPTSQLLOCALDBLICENSETERMS=YES" -Wait 
#Start-Process  "msiexec"  -argumentlist "/passive /i ""$odbc"" IACCEPTMSODBCSQLLICENSETERMS=YES" -Wait 
#Start-Process  "msiexec"  -argumentlist "/passive /i ""$CmdLineUtil"" IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES" -Wait 


