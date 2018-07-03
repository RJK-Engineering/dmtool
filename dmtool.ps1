<#

.SYNOPSIS
IBM Deployment Manager tool.

.DESCRIPTION
Build IBM Deployment Manager deployment operation files and perform the
operations they specify using the Deployment Manager command-line interface.

.EXAMPLE
dmtool.ps1 -Build `
-Package "C:\packages\deployment_20120101-1.zip" `
-SourceEnvironment "Development" `
-Pair "Development - Test" `
-TemplateDir "C:\dmtool\Templates" `
-DataSetDir "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Development\Assets" `
-ConvertedDataSetDir "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Test\Assets"

Build deployment operation files for deployment_20120101-1.zip
for deployment on Test with Development as source.

Creates:
C:\packages\deployment_20120101-1\AnalyzeDeployDataSet.xml
C:\packages\deployment_20120101-1\ConvertDeployDataSet.xml
C:\packages\deployment_20120101-1\ImportOptions.xml
C:\packages\deployment_20120101-1\ExpandDeployPackage.xml
C:\packages\deployment_20120101-1\ImportDeployDataSet.xml

.EXAMPLE
dmtool.ps1 -Build `
-PackageDir "C:\packages" `
-SourceEnvironment "Development" `
-Pair "Development - Test" `
-TemplateDir "C:\dmtool\Templates" `
-DataSetDir "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Development\Assets" `
-ConvertedDataSetDir "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Test\Assets"

Build deployment operation files for all packages in C:\packages.

.EXAMPLE
dmtool.ps1 -Deploy -Package deployment_20120101-1.zip -Password ***

Perform deployment operations for deployment_20120101-1.zip.

.EXAMPLE
dmtool.ps1 -Deploy -PackageDir C:\packages -Password ***

Perform deployment operations for all packages in C:\packages.

.EXAMPLE
dmtool.ps1 -Deploy

Perform deployment operations for all packages in current working directory and ask for password.

.NOTES
Deployment operations reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm

Import options reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_mgr_command_line_importoptions_syntax.htm

.LINK
https://github.com/RJK-Engineering/dmtool

#>

param (
    # Build deployment operation files.
    [switch]$Build,
    # Perform deployment operations.
    [switch]$Deploy,

    # Path to deployment package.
    [string]$Package,
    # Path to directory containing deployment packages.
    [string]$PackageDir,

    # Source environment name.
    [string]$SourceEnvironment,
    # Source-destination pair name.
    [string]$Pair,
    # Password.
    [string]$Password,

    # Path to existing import option XML.
    [string]$OptionSet,
    # DeploymentOption XML version.
    # Default value: 5.2.1
    [string]$DeploymentOptionsVersion = "5.2.1",

    # Path to directory containing deployment operation file templates.
    [string]$TemplateDir,
    # Path to deployment data set directory.
    [string]$DataSetDir,
    # Path to converted deployment data set directory.
    # Default value: -DataSetDir parameter value
    [string]$ConvertedDataSetDir = $($DataSetDir),

    # Path to deployment manager executable.
    # Default value: C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\DeploymentManagerCmd
    [string]$DeploymentManager = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\DeploymentManagerCmd",
    # Path to deployment tree.
    # Default value: C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData
    [string]$DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData",
    # Deployment tree version.
    # Default value: 5.2.0
    [string]$DeploymentTreeVersion = "5.2.0",

    # Name of file created by AnalyzeDeployDataSet operation.
    # File will be stored in converted deploy data set directory.
    [string]$AnalysisReportFileName = "ChangeImpactReport.xml",

    # Display help.
    [switch]$help,
    # Do not execute Deployment Manager but display command.
    [switch]$test
)

if ($help) {
    Get-Help $PSCommandPath -detailed
    exit
} elseif (! ($Build -or $Deploy)) {
    "Use -Build or -Deploy."
    exit
}

$ExpandDeployPackageXML = "ExpandDeployPackage.xml"
$ConvertDeployDataSetXML = "ConvertDeployDataSet.xml"
$AnalyzeDeployDataSetXML = "AnalyzeDeployDataSet.xml"
$ImportDeployDataSetXML = "ImportDeployDataSet.xml"
$ImportOptionsXML = "ImportOptions.xml"

###########################################################

function GetXML {
    <#
        .DESCRIPTION
        Get XML from template directory.
    #>
    param (
        # XML filename
        [string]$file
    )

    [xml]$xml = Get-Content "$TemplateDir\$file" -ErrorAction Stop

    $el = $xml.DeploymentOperation
    $el.deploymentTreeLocation = $DeploymentTree
    $el.version = $DeploymentTreeVersion

    $xml
}

function WriteXML( [xml]$xml, [string]$file ) {
    $out = "$xmlDir\$file"
    try {
        $xml.Save($out)
    } catch {
        $error[0].Exception
        exit
    }
    "Created: $out"
}

function CreateExpandDeployPackageXML( [string]$packagePath ) {
    $createEnvironment="false"
    $halfMapMode="merge"

    $xml = GetXML $ExpandDeployPackageXML
    $el = $xml.DeploymentOperation.ExpandDeployPackage
    $el.createEnvironment = $createEnvironment
    $el.halfMapMode = $halfMapMode

    $el.Environment = $SourceEnvironment
    $el.DeployDataSet = $DeployDataSet
    $el.DeployPackage = "" # will be set on deployment

    WriteXML $xml $ExpandDeployPackageXML
}

function CreateConvertDeployDataSetXML {
    $deleteDestinationFilesOnError="false"

    $xml = GetXML $ConvertDeployDataSetXML
    $el = $xml.DeploymentOperation.ConvertDeployDataSet
    $el.deleteDestinationFilesOnError = $deleteDestinationFilesOnError

    $el.Pair = $Pair
    $el.SourceDeployDataSet = $DeployDataSet
    $el.ConvertedDeployDataSet = $ConvertedDeployDataSet

    WriteXML $xml $ConvertDeployDataSetXML
}

function CreateAnalyzeDeployDataSetXML {
    $analysisFailuresLimit="100" # default: 100
    $deleteAnalysisResultsFileOnError="false"
    $importUpdateOption="UpdateAlways" # options: UpdateIfNewer UpdateAlways UpdateNotAllowed
    $generateDetailedReport="true"

    $xml = GetXML $AnalyzeDeployDataSetXML
    $el = $xml.DeploymentOperation.AnalyzeDeployDataSet
    $el.analysisFailuresLimit = $analysisFailuresLimit
    $el.deleteAnalysisResultsFileOnError = $deleteAnalysisResultsFileOnError
    $el.importUpdateOption = $importUpdateOption
    $el.Pair = $Pair
    $el.DeployDataSet = $ConvertedDeployDataSet

    $el = $el.ValidationOutput
    $el.generateDetailedReport = $generateDetailedReport
    $el.AnalysisReportFileName = "$ConvertedDeployDataSet\$AnalysisReportFileName"

    WriteXML $xml $AnalyzeDeployDataSetXML
}

function CreateImportDeployDataSetXML {
    $xml = GetXML $ImportDeployDataSetXML
    $el = $xml.DeploymentOperation.ImportDeployDataSet
    $el.Environment = $SourceEnvironment
    $el.DeployDataSet = $ConvertedDeployDataSet
    $el.OptionSetPath = "" # will be set on deployment

    WriteXML $xml $ImportDeployDataSetXML
}

function CreateOptionSetXML {
    [xml]$xml = Get-Content $OptionSet -ErrorAction Stop

    $el = $xml.DeploymentOptions
    $el.version = $DeploymentOptionsVersion

    # $el = $el.ImportOptions
    # $el.Environment = "environment_name"
    # $el.DeployDataSet = "deploy_dataset_name"

    # $el.UpdateOption = "UpdateIfNewer|UpdateAlways|UpdateNotAllowed"
    # $el.CreateOption = "CreateAlways|CreateNotAllowed"
    # $el.WorkflowConfigurationOption = "Overwrite|Merge"

    # $el.ImportSecurity.value = "true|false"
    # $el.ImportOwner.value = "true|false"
    # $el.ImportObjectId.value = "true|false"
    # $el.UseOriginalTimestamps.value = "true|false"
    # $el.ImportRetention.value = "true|false"
    # $el.RemovePropertyDefinitions.value = "true|false"
    # $el.TransferWorkflows.value = "true|false"

    # $el.AuditOption = "AuditOnly|ImportWithAudit|ImportOnly"

    # $el.DeleteCreatedFilesOnError.value = "true|false"
    # $el.ReportFileName = "AuditFile"

    # $el.UpdateLocalizedProperties.value = "true|false"

    # $el = $el.StoragePolicy
    # $el.type = "DefaultOnClassOnDestination|PropertyOnExportedObject|SpecificOnDestination"
    # $el.ID = "storage_policy_GUID"

    WriteXML $xml $ImportOptionsXML
}

###########################################################

function BuildOperationFiles( [System.IO.FileInfo]$pkg ) {
    "Processing $pkg ..."
    $packageName = $pkg.BaseName
    $DeployDataSet = "$DataSetDir\$packageName"
    "Deploy data set: $DeployDataSet"
    $ConvertedDeployDataSet = "$ConvertedDataSetDir\$packageName.converted"
    "Converted ddset: $ConvertedDeployDataSet"

    $xmlDir = "$($pkg.Directory.FullName)\$($pkg.BaseName)"
    if (-not (Test-Path $xmlDir)) {
        $null = mkdir $xmlDir
        "Created $xmlDir"
    }

    CreateExpandDeployPackageXML $pkg.FullName
    CreateConvertDeployDataSetXML
    CreateAnalyzeDeployDataSetXML
    CreateImportDeployDataSetXML
    CreateOptionSetXML
}

function Deploy( [System.IO.FileInfo]$pkg ) {
    $xmlDir = "$($pkg.Directory.FullName)\$($pkg.BaseName)"
    if (-not (Test-Path $xmlDir)) {
        "Deployment operation file directory does not exist: $xmlDir"
    }

    $path = "$xmlDir\$ExpandDeployPackageXML"
    SetDeployPackage $path $pkg.FullName
    "ExpandDeployPackage"
    Run $path

    "ConvertDeployDataSet"
    Run "$xmlDir\$ConvertDeployDataSetXML"

    if (! $Password) {
        $Password = Read-Host -prompt "Password:"
    }

    "AnalyzeDeployDataSet"
    Run "$xmlDir\$AnalyzeDeployDataSetXML" $Password

    "ImportDeployDataSet"
    $path = "$xmlDir\$ImportDeployDataSetXML"
    SetOptionSet $path "$xmlDir\$ImportOptionsXML"
    Run $path $Password
}

function Run( [string]$opFile, [string]$password ) {
    "Press enter to continue, ctrl+c to stop"
    Read-Host
    if ($Test) {
        "& $DeploymentManager -o $opFile -p $password"
    } elseif ($Password) {
        & $DeploymentManager -o $opFile -p $password
    } else {
        & $DeploymentManager -o $opFile
    }
}

function SetDeployPackage( [string]$ExpandDeployPackagePath, [string]$DeployPackagePath ) {
    "DeployPackage: $DeployPackagePath"
    [xml]$xml = Get-Content $ExpandDeployPackagePath -ErrorAction Stop

    $xml.DeploymentOperation.ExpandDeployPackage.DeployPackage = $DeployPackagePath
    try {
        $xml.Save($ExpandDeployPackagePath)
    } catch {
        $error[0].Exception
        exit
    }
}

function SetOptionSet( [string]$ImportDeployDataSetPath, [string]$OptionSetPath ) {
    "OptionSet: $OptionSetPath"
    [xml]$xml = Get-Content $ImportDeployDataSetPath -ErrorAction Stop

    $xml.DeploymentOperation.ImportDeployDataSet.OptionSetPath = $OptionSetPath
    try {
        $xml.Save($ImportDeployDataSetPath)
    } catch {
        $error[0].Exception
        exit
    }
}

###########################################################

function GetPackages {
    if ($Package) {
        Get-Item $Package -ErrorAction Stop
    } else {
        if (! $PackageDir) { $PackageDir = "." }
        $PackageDir = Resolve-Path $PackageDir -ErrorAction Stop

        $packages = Get-ChildItem $PackageDir -filter *.zip -ErrorAction Stop
        if (! $packages) {
            write-host "No packages found in $PackageDir"
            exit
        }
        write-host "Found $($packages.count) package(s) in $PackageDir"
        $packages
    }
}

$packages = GetPackages

if ($Build) {
    $TemplateDir = Resolve-Path $TemplateDir -ErrorAction Stop
    "Template directory: $TemplateDir"
    "Deployment tree: $DeploymentTree"
    "Analysis report: $AnalysisReportFileName"

    if ($OptionSet) {
        $OptionSet = Resolve-Path $OptionSet -ErrorAction Stop
    } else {
        $OptionSet = Resolve-Path "$TemplateDir\$ImportOptionsXML"
    }
    "Option set: $OptionSet"
    "Source environment: $SourceEnvironment"
    "Source-destination pair: $Pair`n"

    $action = "BuildOperationFiles"
} else {
    $action = "Deploy"
}

foreach ($pkg in $packages) {
    & $action $pkg
}

"Done."
