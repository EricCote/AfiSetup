
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


$sourceSqlLocalDb = "https://download.microsoft.com/download/E/1/2/E12B3655-D817-49BA-B934-CEB9DAC0BAF3/SqlLocalDB.msi";
$SqlLocalDb= ($dl + "SqlLocalDB.msi")

Download-File $sourceSqlLocalDb $SqlLocalDb

$sourceOdbc = "https://download.microsoft.com/download/D/5/E/D5EEF288-A277-45C8-855B-8E2CB7E25B96/13.1.811.168/amd64/msodbcsql.msi"
$odbc = ($dl + "msodbcsql.msi")

Download-File $sourceOdbc $odbc

$sourceCmdLineUtil = "https://download.microsoft.com/download/C/8/8/C88C2E51-8D23-4301-9F4B-64C8E2F163C5/Command%20Line%20Utilities%20MSI%20files/amd64/MsSqlCmdLnUtils.msi"
$CmdLineUtil = ($dl + "MsSqlCmdLnUtils.msi")

Download-File $sourceCmdLineUtil $CmdLineUtil

Start-Process  "msiexec"  -argumentlist "/passive /i ""$SqlLocalDb"" IACCEPTSQLLOCALDBLICENSETERMS=YES" -Wait 
Start-Process  "msiexec"  -argumentlist "/passive /i ""$odbc"" IACCEPTMSODBCSQLLICENSETERMS=YES" -Wait 
Start-Process  "msiexec"  -argumentlist "/passive /i ""$CmdLineUtil"" IACCEPTMSSQLCMDLNUTILSLICENSETERMS=YES" -Wait 


del $SqlLocalDb
del $odbc
del $CmdLineUtil



#$SourceOdbc13dot0 = "https://download.microsoft.com/download/1/E/7/1E7B1181-3974-4B29-9A47-CC857B271AA2/English/X64/msodbcsql.msi"
#$sourceCmdLineUtil13dot0 = "https://download.microsoft.com/download/C/8/E/C8ECE442-C29C-4EE4-BD73-872C03D9EB84/ENG_1033/x64/SqlCmdLnUtils.msi"

#"https://download.microsoft.com/download/E/1/2/E12B3655-D817-49BA-B934-CEB9DAC0BAF3/SQLEXPR_x64_ENU.exe" 
#"https://download.microsoft.com/download/E/1/2/E12B3655-D817-49BA-B934-CEB9DAC0BAF3/SQLEXPRADV_x64_ENU.exe"
#"https://download.microsoft.com/download/E/1/2/E12B3655-D817-49BA-B934-CEB9DAC0BAF3/SqlLocalDB.msi"
