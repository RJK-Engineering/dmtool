@echo off

if not defined DMTOOL set DMTOOL=%~dp0..
set SOURCE=Ontwikkel
set DESTINATION=PROD
REM set PAIR=Ontw to Prod

call %DMTOOL%\bat\Deploy.bat %*
