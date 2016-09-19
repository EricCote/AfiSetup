Set-ExecutionPolicy -scope process  bypass


$dl=$env:USERPROFILE + "\downloads\"

function detect-localdb 
{ 
  if ((Get-childItem -ErrorAction Ignore -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions\").Length -gt 0) 
  {
   return $true
  } else { return $false }
}



function Get-ServerName
{
    $svr=""
    if((Get-ItemProperty -ErrorAction Ignore "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\" ).MSSQLSERVER.Length -gt  0)
    { $svr="." }
    elseif  ((Get-childItem -ErrorAction Ignore -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions\").Length -gt 0) 
    { $svr="(localdb)\MSSQLLocalDB" }

    return $svr
}


function Download-FromEdge
{
 param 
    (
        [parameter(position=1,mandatory=$true)] $url,
        [parameter(position=2,mandatory=$true)] $filename

    )  

    & "cmd.exe" (" /c start Microsoft-Edge:" + $url)


    write-host "Waiting file to finish downloading" -NoNewline
    while ( -not (Test-Path (Join-path $dl  $filename)))
    {
        write-host "." -NoNewline
        start-sleep -Seconds 3
    }
    "Download completed."    
}

function Stop-EdgeBrowser
{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName Microsoft.VisualBasic

    $edge= Get-Process -name microsoftEdge
    do {
        [Microsoft.VisualBasic.Interaction]::AppActivate("edge")
        start-sleep -Milliseconds 1500
        [System.Windows.Forms.SendKeys]::SendWait("%{F4}")
        start-sleep -Milliseconds 700
        [System.Windows.Forms.SendKeys]::SendWait("~")
        start-sleep -Milliseconds 3000
    }
    until ($edge[0].HasExited)
}


function Run-Sql
{
    param 
    (
        [parameter(position=1,mandatory=$true)] $sqlString
    )   

    $sqlcmd=""
    if (test-path "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe")
    {$sqlcmd="C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe";};

    if (test-path "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE")
    {$sqlcmd="C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\SQLCMD.EXE";};

    if (test-path "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE")
    {$sqlcmd="C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\SQLCMD.EXE";};

    $svr=Get-ServerName


    return & $sqlcmd -S $svr -E -Q $SqlString
}

function Get-SqlEdition
{   
    $aString = Run-Sql "SELECT SERVERPROPERTY ('edition') as x";
    
    if  (($aString | Select-String '(\w+) Edition') -match  '(\w+) Edition' )
    {return $Matches[1];}

}

function Get-SqlYear
{
  
    $versionString = Run-Sql "SELECT @@Version";
   
    if (($versionString  | Select-String 'Microsoft SQL Server (\d+)') -match  'Microsoft SQL Server (\d+)' )
    {
        return [int]::Parse($Matches[1]);
    }
    else 
    {
        return 0
    }

}

function Get-codeplexVersion
{
   $response= Invoke-WebRequest -uri "http://www.codeplex.com/";
   if ($response.RawContent -match "<li>Version \d+\.\d+\.\d+\.(\d+)</li>")
   {   return $Matches[1]; };
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


function Enable-AutomaticDownloadEdge
{
    #enable automatic download
    New-Item -name Download -path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\"
             

    Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Download" `
                               -Name "EnableSavePrompt" -Value 0 
}


if (Get-ServerName -neq '')
{

    if ((Get-ServerName) -eq '(localdb)\MSSQLLocalDB')
    {
        
        & "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
        & "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb
       
    }



    #get codeplex-Version
    $codeplexVersion= Get-CodeplexVersion

   

    New-Item -type directory -path C:\aw
    $Acl = Get-Acl "C:\aw"
    $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("BUILTIN\Users","FullControl","ContainerInherit,ObjectInherit","None","Allow")
    $Acl.AddAccessRule($ar)
    Set-Acl "C:\aw" $Acl

    ###------------------------------------------------------

    $FileNameAW2014=Join-path $dl  "Adventure Works 2014 Full Database Backup.zip"

    Download-File "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=880661&FileTime=130507138100830000&Build=$codeplexVersion" $FileNameAW2014

    add-type -AssemblyName System.IO.Compression.FileSystem
    [system.io.compression.zipFile]::ExtractToDirectory($FileNameAW2014,'c:\aw\')


    $cmd="
    RESTORE DATABASE AdventureWorks2014
      FROM DISK = 'C:\AW\AdventureWorks2014.bak'
    WITH   
      MOVE 'AdventureWorks2014_Data' 
      TO 'C:\AW\AdventureWorks_data.mdf', 
      MOVE 'AdventureWorks2014_Log' 
      TO 'C:\AW\AdventureWorks_log.ldf';
    "

    run-sql $cmd



    ###----------------------------------------------------


    $FileNameAWDW2014=Join-path $dl  "Adventure Works DW 2014 Full Database Backup.zip"

    Download-File "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=880664&FileTime=130511246406570000&Build=$codeplexVersion" $FileNameAWDW2014


    add-type -AssemblyName System.IO.Compression.FileSystem
    [system.io.compression.zipFile]::ExtractToDirectory($FileNameAWDW2014,'c:\aw\')



    $cmd="
    RESTORE DATABASE AdventureWorksDW2014
      FROM DISK = 'C:\AW\AdventureWorksDW2014.bak'
    WITH   
      MOVE 'AdventureWorksDW2014_Data' 
      TO 'C:\AW\AdventureWorksDW_data.mdf', 
      MOVE 'AdventureWorksDW2014_Log' 
      TO 'C:\AW\AdventureWorksDW_log.ldf';
    "

    run-sql $cmd


    ###-------------------------------------------------------------------------------

    $FileNameAWLT2012 = Join-path $dl "AdventureWorksLT2012_Data.mdf";

    Download-File  "http://download-codeplex.sec.s-msft.com/Download/Release?ProjectName=msftdbprodsamples&DownloadId=354847&FileTime=129764108568330000&Build=$codeplexVersion" $FileNameAWLT2012

    Copy-Item  -Path $FileNameAWLT2012 -Destination 'c:\aw\'

    $cmd="
    CREATE DATABASE AdventureWorksLT2012 ON 
    ( FILENAME = N'C:\aw\AdventureWorksLT2012_Data.mdf' )
     FOR ATTACH_REBUILD_LOG  ;
    "

    run-sql $cmd


    ###-------------------------------------------------------------------------------


    if (get-sqlYear -get 2016)
    {
      $SqlFeature="Standard"
      if(("Enterprise","Developer") -contains (Get-SqlEdition))
      { $SqlFeature="Full" }
 

    Download-File ("https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-" + $SqlFeature + ".bak")  (Join-path $dl  ("WideWorldImporters-" + $SqlFeature + ".bak"))



    Copy-Item  -Path (Join-path $dl  "WideWorldImporters-*.bak") -Destination 'c:\aw\'

    $part=""
    if ($SqlFeature -eq "Full") 
    {  $part = " MOVE 'WWI_InMemory_Data_1' TO 'c:\AW\WideWorldImporters_InMemory_Data_1', " };

    $cmd="
    RESTORE DATABASE WideWorldImporters
      FROM DISK = 'C:\AW\WideWorldImporters-" +  $SqlFeature  +  ".bak'
    WITH   
      MOVE 'WWI_Primary' 
      TO 'C:\AW\WideWorldImporters.mdf', 
      MOVE 'WWI_UserData' 
      TO 'C:\AW\WideWorldImporters_UserData.ndf',
    "  + $part + "
      MOVE 'WWI_Log' 
      TO 'C:\AW\WideWorldImporters.ldf';
    "


    Run-Sql $cmd



    ###-------------------------------------------------------------------------------





    Download-File "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImportersDW-$SqlFeature.bak" (Join-path $dl "WideWorldImportersDW-$SqlFeature.bak")


    Copy-Item  -Path (Join-path $dl  "WideWorldImportersDW-*.bak") -Destination 'c:\aw\'

    $part=""
    if ($SqlFeature -eq "Full") 
    {  $part =  " MOVE 'WWIDW_InMemory_Data_1' TO 'c:\AW\WideWorldImportersDW_InMemory_Data_1', "  };


    $cmd="
    RESTORE DATABASE WideWorldImportersDW
      FROM DISK = 'C:\AW\WideWorldImportersDW-" +  $SqlFeature  +  ".bak'
    WITH   
      MOVE 'WWI_Primary' 
      TO 'C:\AW\WideWorldImportersDW.mdf', 
      MOVE 'WWI_UserData' 
      TO 'C:\AW\WideWorldImportersDW_UserData.ndf',
    "  + $part + "
      MOVE 'WWI_Log' 
      TO 'C:\AW\WideWorldImportersDW.ldf';
    "


    run-sql $cmd


    }



    #####---------------------------------------------------------------------------------------------


    del $FileNameAW2014
    del $FileNameAWDW2014
    del $FileNameAWLT2012
    del (Join-path $dl  "WideWorldImporters*.bak") 


}
else
{
    "No SQL Server detected!"
}

if ($uninstall -eq $true)
{
    run-sql "DROP DATABASE WideWorldImportersDW;"
    run-sql "DROP DATABASE WideWorldImporters;"
    run-sql "DROP DATABASE AdventureWorksLT2012;"
    run-sql "DROP DATABASE AdventureWorksDW2014;"
    run-sql "DROP DATABASE AdventureWorks2014;"

}