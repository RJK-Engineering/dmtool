@echo off

set PASSWORD=%1
IF "%PASSWORD%"=="" GOTO NOPASS

set ENVOPTS=-SourceEnvironment '%SOURCE%' -DestinationEnvironment '%DESTINATION%' -Pair '%PAIR%'
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& %DMTOOL%\dmtool.ps1 -Build  %ENVOPTS% -Log %2 %3 %4"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& %DMTOOL%\dmtool.ps1 -Deploy %ENVOPTS% -Log -Password '%PASSWORD%' %2 %3 %4"
goto END

:NOPASS
echo Geen password opgegeven

:END
