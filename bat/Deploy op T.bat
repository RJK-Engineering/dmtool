@echo off
REM ========= CONFIGURATIE =========

set DMTOOL=D:\dmtool\dmtool.ps1
set SOURCE=Ontwikkel
set DESTINATION=Test
set PAIR=Ontw to Test

REM ================================

set PASSWORD=%1
IF "%PASSWORD%"=="" GOTO NOPASS

set ENVOPTS=-SourceEnvironment '%SOURCE%' -DestinationEnvironment '%DESTINATION%' -Pair '%PAIR%'
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& %DMTOOL% -Build  %ENVOPTS% -Log"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& %DMTOOL% -Deploy %ENVOPTS% -Log -Password '%PASSWORD%'"
goto END

:NOPASS
echo Geen password opgegeven

:END
