﻿
Set-ExecutionPolicy -scope process  bypass



$dl=$env:USERPROFILE + "\downloads\"

function detect-localdb 
{ 
  if ((Get-childItem -ErrorAction Ignore -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions\").Length -gt 0) 
  {
   return $true
  } else { return $false }
}


#[HKEY_CURRENT_USER\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Download]
#"EnableSavePrompt"=dword:00000000

New-Item -name Download -path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\"
             

Set-ItemProperty -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Download" `
                           -Name "EnableSavePrompt" -Value 0 

&start Microsoft-Edge:https://msftdbprodsamples.codeplex.com/downloads/get/880661


###------------------------------------------------------

write-host "Waiting file to finish downloading" -NoNewline
while ( -not (Test-Path (Join-path $dl  "Adventure Works 2014 Full Database Backup.zip")))
{
    write-host "." -NoNewline
    start-sleep -Seconds 3
}
"Download completed."

add-type -AssemblyName System.IO.Compression.FileSystem
[system.io.compression.zipFile]::ExtractToDirectory((Join-path $dl  "Adventure Works 2014 Full Database Backup.zip"),'c:\aw\')


& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb

$cmd="
RESTORE DATABASE AdventureWorks2014
  FROM DISK = 'C:\AW\AdventureWorks2014.bak'
WITH   
  MOVE 'AdventureWorks2014_Data' 
  TO 'C:\AW\AdventureWorks_data.mdf', 
  MOVE 'AdventureWorks2014_Log' 
  TO 'C:\AW\AdventureWorks_log.ldf';
"

&  "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd" -S "(localdb)\MSSQLLocalDB"   -E -Q $cmd



###----------------------------------------------------



&start Microsoft-Edge:https://msftdbprodsamples.codeplex.com/downloads/get/880664


write-host "Waiting file to finish downloading" -NoNewline
while ( -not (Test-Path (Join-path $dl  "Adventure Works DW 2014 Full Database Backup.zip")))
{
    write-host "." -NoNewline
    start-sleep -Seconds 3
}
"Download completed."




add-type -AssemblyName System.IO.Compression.FileSystem
[system.io.compression.zipFile]::ExtractToDirectory((Join-path $dl  "Adventure Works DW 2014 Full Database Backup.zip"),'c:\aw\')


& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb

$cmd="
RESTORE DATABASE AdventureWorksDW2014
  FROM DISK = 'C:\AW\AdventureWorksDW2014.bak'
WITH   
  MOVE 'AdventureWorksDW2014_Data' 
  TO 'C:\AW\AdventureWorksDW_data.mdf', 
  MOVE 'AdventureWorksDW2014_Log' 
  TO 'C:\AW\AdventureWorksDW_log.ldf';
"

&  "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd" -S "(localdb)\MSSQLLocalDB"   -E -Q $cmd


###-------------------------------------------------------------------------------





&start Microsoft-Edge:https://msftdbprodsamples.codeplex.com/downloads/get/354847


write-host "Waiting file to finish downloading" -NoNewline
while ( -not (Test-Path (Join-path $dl  "AdventureWorksLT2012_Data.mdf")))
{
    write-host "." -NoNewline
    start-sleep -Seconds 3
}
"Download completed."

Copy-Item  -Path (Join-path $dl  "AdventureWorksLT2012_Data.mdf") -Destination 'c:\aw\'



& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb

$cmd="
CREATE DATABASE AdventureWorksLT2012 ON 
( FILENAME = N'C:\aw\AdventureWorksLT2012_Data.mdf' )
 FOR ATTACH_REBUILD_LOG  ;
"

&  "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd" -S "(localdb)\MSSQLLocalDB"   -E -Q $cmd


###-------------------------------------------------------------------------------




&start Microsoft-Edge:https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bak
#https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-.bak

write-host "Waiting file to finish downloading" -NoNewline
while ( -not (Test-Path (Join-path $dl  "WideWorldImporters-Standard.bak")))
{
    write-host "." -NoNewline
    start-sleep -Seconds 3
}
"Download completed."

Copy-Item  -Path (Join-path $dl  "WideWorldImporters-Standard.bak") -Destination 'c:\aw\'


& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb

$cmd="
RESTORE DATABASE WideWorldImporters
  FROM DISK = 'C:\AW\WideWorldImporters-Standard.bak'
WITH   
  MOVE 'WWI_Primary' 
  TO 'C:\AW\WideWorldImporters.mdf', 
  MOVE 'WWI_UserData' 
  TO 'C:\AW\WideWorldImporters_UserData.ndf',
  --MOVE 'WWI_InMemory_Data_1' 
  --TO 'c:\AW\WideWorldImporters_InMemory_Data_1',
  MOVE 'WWI_Log' 
  TO 'C:\AW\WideWorldImporters.ldf';
"


&  "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd" -S "(localdb)\MSSQLLocalDB"   -E -Q $cmd



###-------------------------------------------------------------------------------





&start Microsoft-Edge:https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImportersDW-Standard.bak


write-host "Waiting file to finish downloading" -NoNewline
while ( -not (Test-Path (Join-path $dl  "WideWorldImportersDW-Standard.bak")))
{
    write-host "." -NoNewline
    start-sleep -Seconds 3
}
"Download completed."

Copy-Item  -Path (Join-path $dl  "WideWorldImportersDW-Standard.bak") -Destination 'c:\aw\'



& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" start 
& "C:\Program Files\Microsoft SQL Server\130\Tools\Binn\SqlLocalDB.exe" info mssqllocaldb

$cmd="
RESTORE DATABASE WideWorldImportersDW
  FROM DISK = 'C:\AW\WideWorldImportersDW-Standard.bak'
WITH   
  MOVE 'WWI_Primary' 
  TO 'C:\AW\WideWorldImportersDW.mdf', 
  MOVE 'WWI_UserData' 
  TO 'C:\AW\WideWorldImportersDW_UserData.ndf',
  --MOVE 'WWI_InMemory_Data_1' 
  --TO 'c:\AW\WideWorldImporters_InMemory_Data_1',
  MOVE 'WWI_Log' 
  TO 'C:\AW\WideWorldImportersDW.ldf';
"


&  "C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd" -S "(localdb)\MSSQLLocalDB"   -E -Q $cmd






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


