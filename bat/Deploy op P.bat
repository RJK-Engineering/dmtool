@echo off

if not defined DMTOOL set DMTOOL=D:\dmtool
set SOURCE=Ontwikkel
set DESTINATION=PROD
REM set PAIR=Ontw to Prod

call %DMTOOL%\bat\Deploy.bat %*
