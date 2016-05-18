

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser



Get-PackageProvider -ListAvailable 

Install-PackageProvider -Name NuGet 
Import-PackageProvider -Name  NuGet 
Install-Module ScriptBrowser –Scope CurrentUser
Import-Module ScriptBrowser



Get-PackageProvider -ListAvailable 


Enable-ScriptBrowser
Enable-ScriptAnalyzer