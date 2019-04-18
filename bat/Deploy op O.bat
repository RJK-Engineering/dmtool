@echo off

if not defined DMTOOL set DMTOOL=%~dp0..
set SOURCE=Ontwikkel
set DESTINATION=OokOntwikkel
set PAIR=OO

call %DMTOOL%\bat\Deploy.bat %*
