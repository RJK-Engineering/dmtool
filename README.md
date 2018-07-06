# dmtool

![.\dmtool.ps1 -Help](help.png)

# Description

Build IBM Deployment Manager deployment operation files and perform the
operations they specify using the command-line interface.

# Allow running of PowerShell scripts

```
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

# Deployment operations

## setup
[RetrievePrincipalInfoFromDomain](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrievePrincipalInfoFromDomain_main)
[RetrievePrincipalInfoFromDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrievePrincipalInfoFromDeployDataSet_main)
[RetrieveObjectStoreInfoFromDomain](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrieveObjectStoreInfoFromDomain_main)
[RetrieveObjectStoreInfoFromDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrieveObjectStoreInfoFromDeployDataSet_main)
[RetrieveServiceInfoFromDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrieveServiceInfoFromDeployDataSet_main)
[RetrieveInfoFromEnvironment](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrieveInfoFromEnvironment_main)
[CreateEnvironment](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__CreateEnvironment_main)
[?ReassignObjectStore](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__?ReassignObjectStore_main)

## source export
[ExportDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__ExportDeployDataSet_main)
[CreateDeployPackage](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__CreateDeployPackage_main)

## destination import
[ExpandDeployPackage](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__ExpandDeployPackage_main)
[ConvertDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__ConvertDeployDataSet_main)
[AnalyzeDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__AnalyzeDeployDataSet_main)
[ImportDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__ImportDeployDataSet_main)

## ?
[MapData](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__MapData_main)
[GenerateAuditReport](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__GenerateAuditReport_main)
[UpgradeDeploymentTree](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__UpgradeDeploymentTree_main)
[RetrieveConnectionPointInfoFromDeployDataSet](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrieveConnectionPointInfoFromDeployDataSet_main)
[RetrieveConnectionPointInfoFromDomain](https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm#deploy_operation_formats__RetrieveConnectionPointInfoFromDomain_main)


# To Do

* Required parameters check
* use $DeploymentTree to construct $datasetdir/$exportmanifest
* Params for:
    * hardcoded per-deployment op. settings
    * optionset
* Logging?
    * use DeploymentManager.exe / DeploymentManagerCmd.bat ?
    * CLI warnings:
        * WARN [main] common.ConsoleThread - Unable to locate default logging configuration file: P:\dmtool\log4j.properties
        * WARN [main] common.ConsoleThread - No log4j appenders could be found - will default to console output only.

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

# Links

Source repository:
https://github.com/RJK-Engineering/dmtool

Deployment operations reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm

Import options reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_mgr_command_line_importoptions_syntax.htm
