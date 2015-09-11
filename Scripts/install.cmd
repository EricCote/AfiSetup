md c:\scripts
copy %~dp0*.* c:\scripts

start %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy bypass -f "c:\scripts\newMachineConfig.ps1"