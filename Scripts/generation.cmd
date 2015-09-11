set src=C:\demo\afisetup

IF EXIST "%src%\7z\out.7z" del "%src%\7z\out.7z"
IF EXIST "%src%\demo4\setup.exe" del "%src%\demo4\setup.exe"

"%src%\7z\7z.exe" a  "%src%\7z\out.7z"  "%src%\scripts\*"  -mx 
copy /b "%src%\7z\7zS2con.sfx" + "%src%\7z\out.7z"  "%src%\demo4\setup.exe"  


::  "C:\Program Files (x86)\Windows Kits\8.1\bin\x86\mt.exe"  -manifest "%src%\7z\manifest.txt" -outputresource:"%src%\7z\7zS2con.sfx";#1


del "%src%\7z\out.7z"



