

#Set-ExecutionPolicy -ExecutionPolicy undefined -Scope CurrentUser
Get-ExecutionPolicy -list


Get-PackageProvider -ListAvailable 
Get-PackageSource 

Install-PackageProvider -Name NuGet -force
Import-PackageProvider -Name  NuGet 
Install-Module ScriptBrowser –Scope CurrentUser
Import-Module ScriptBrowser



Get-PackageProvider -ListAvailable 




Enable-ScriptBrowser
Enable-ScriptAnalyzer