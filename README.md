# dmtool

![.\dmtool.ps1 -Help](help.png)

# Description

Build IBM Deployment Manager deployment operation files and perform the
operations they specify using the command-line interface.

# Allow running of PowerShell scripts

```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

# To Do

* Params for:
    * hardcoded per-deployment op. settings
    * optionset
* Logging?
    * use DeploymentManager.exe / DeploymentManagerCmd.bat ?

## optimization: load templates once!

```
function LoadTemplates {
    $names = @(
        "ExpandDeployPackage",
        "ConvertDeployDataSet",
        "AnalyzeDeployDataSet",
        "ImportDeployDataSet"
    )
    foreach ($name in $names) {
        [xml]$xml = Get-Content "$TemplateDir\$name.xml" -ErrorAction Stop
        $el = $xml.DeploymentOperation
        $el.deploymentTreeLocation = $DeploymentTree
        $el.version = $DeploymentTreeVersion
        $templates.add("$name.xml", $xml)
    }
    $templates
}

$templates = LoadTemplates
```

# Notes

* Using CLI doesn't write anything to C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\deployment.log
* DeploymentManager.exe executes silently in background
* DeploymentManagerCmd.bat prints output and exits when completed
* Both commands DO NOT return an exit code > 0 on error, thus exit code can't be used to check for successful execution
