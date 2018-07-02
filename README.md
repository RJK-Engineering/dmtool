# dmtool

![.\dmtool.ps1 -Help](help.png)

# Description

Build IBM Deployment Manager deployment operation files and perform the
operations they specify using the command-line interface.

# To Do

* params for:
   * hardcoded per-deployment op. settings
   * optionset

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
