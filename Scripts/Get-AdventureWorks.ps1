

$dl=$env:USERPROFILE + "\downloads\"


&start Microsoft-Edge:https://msftdbprodsamples.codeplex.com/downloads/get/880661


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


$dl=$env:USERPROFILE + "\downloads\"


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

del (Join-path $dl  "Adventure Works 2014 Full Database Backup.zip")
del (Join-path $dl  "Adventure Works DW 2014 Full Database Backup.zip")



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

