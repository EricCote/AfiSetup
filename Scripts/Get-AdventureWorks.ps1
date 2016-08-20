Set-ExecutionPolicy -scope process  bypass



$dl=$env:USERPROFILE + "\downloads\"

function detect-localdb 
{ 
  if ((Get-childItem -ErrorAction Ignore -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions\").Length -gt 0) 
  {
   return $true
  } else { return $false }
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

    $svr=""
    if((Get-ItemPropertyValue -ErrorAction Ignore "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL\" "MSSQLSERVER").Length -gt  0)
    { $svr="." }
    else
    { $svr="(localdb)\MSSQLLocalDB" }


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




#enable automatic download
New-Item -name Download -path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\"
             

Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Download" `
                           -Name "EnableSavePrompt" -Value 0 

#start localDB
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb



###------------------------------------------------------

Download-FromEdge  "https://msftdbprodsamples.codeplex.com/downloads/get/880661" "Adventure Works 2014 Full Database Backup.zip"



add-type -AssemblyName System.IO.Compression.FileSystem
[system.io.compression.zipFile]::ExtractToDirectory((Join-path $dl  "Adventure Works 2014 Full Database Backup.zip"),'c:\aw\')


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



Download-FromEdge  "https://msftdbprodsamples.codeplex.com/downloads/get/880664" "Adventure Works DW 2014 Full Database Backup.zip"


add-type -AssemblyName System.IO.Compression.FileSystem
[system.io.compression.zipFile]::ExtractToDirectory((Join-path $dl  "Adventure Works DW 2014 Full Database Backup.zip"),'c:\aw\')



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



Download-FromEdge  "https://msftdbprodsamples.codeplex.com/downloads/get/354847" "AdventureWorksLT2012_Data.mdf"


Copy-Item  -Path (Join-path $dl  "AdventureWorksLT2012_Data.mdf") -Destination 'c:\aw\'


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


del (Join-path $dl  "Adventure Works 2014 Full Database Backup.zip")
del (Join-path $dl  "Adventure Works DW 2014 Full Database Backup.zip")
del (Join-path $dl  "AdventureWorksLT2012_Data.mdf") 
del (Join-path $dl  "WideWorldImporters-Standard.bak") 
del (Join-path $dl  "WideWorldImportersDW-Standard.bak") 


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





