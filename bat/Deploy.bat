@echo off

echo.%*|findstr/I/C:"-password" >nul 2>&1 || goto NOPASSWORD

IF "%DMTOOL%"=="" GOTO HELP
IF NOT EXIST "%DMTOOL%" GOTO DNE
IF "%SOURCE%"=="" GOTO HELP
IF "%DESTINATION%"=="" GOTO HELP

set ENVOPTS=-SourceEnvironment '%SOURCE%' -DestinationEnvironment '%DESTINATION%' -Pair '%PAIR%'
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& %DMTOOL%\dmtool.ps1 -Deploy %ENVOPTS% -Log %*"
goto END

:NOPASSWORD
echo Geen password opgegeven, gebruik: -password [geheimwachtwoord]
goto END

:HELP
echo De volgende omgevingsvariabelen moeten gedefinieerd zijn: DMTOOL SOURCE DESTINATION PAIR
goto END

:DNE
echo Pad bestaat niet: set DMTOOL=%DMTOOL%
goto END

:END
