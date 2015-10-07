
function Set-AutoLogon 
{
    param
    (
        $domainName,
        $loginName,
        $password,
        $count = 0
    )


    if ($domainName)
    {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultDomainName -Value $domainName
    }
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName  -Value $loginName 
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword  -Value $password 
    if ($count -gt 0)
    {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value $count 
    }
}

function Get-ScriptPath
{

  if ($MyInvocation.PSScriptRoot) 
  {
     return $MyInvocation.PSScriptRoot
  }
  else
  {
    return "c:\scripts"
  }

}


Set-ExecutionPolicy bypass -Scope LocalMachine
tzutil /s "Eastern Standard Time"
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -Value 0
Set-AutoLogon -loginName '.\afi' -password 'afi12345!' -count 5 
Set-ItemProperty -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -name "myScript" -value ('cmd /c start powershell -ExecutionPolicy bypass -f "' + (Join-Path (Get-ScriptPath) "newMachineConfig.ps1" ) + '"')

shutdown -r -t 60


