@echo off

if not defined DMTOOL set DMTOOL=D:\dmtool
set SOURCE=Ontwikkel
set DESTINATION=Test
REM set PAIR=Ontw to Test

call %~dp0Deploy.bat %*
