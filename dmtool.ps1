<#

.SYNOPSIS
IBM Deployment Manager tool.

.DESCRIPTION
Build IBM Deployment Manager deployment operation files and perform the
operations they specify using the Deployment Manager command-line interface.

Actions: -Export, -Build, -Deploy

Required parameters for -Export:
- TemplateDir
- SourceEnvironment
- Manifest
- DataSetDir
Optional:
- Package (default: create package in current working directory using name of -Manifest)
- Password (default: prompt for user input)

Required parameters for -Build:
- TemplateDir
- SourceEnvironment
- DestinationEnvironment
Optional:
- Pair (default: "[SourceEnvironment] - [DestinationEnvironment]")
- DeploymentTree (default: "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData")
- Package or PackageDir (default: take all packages in current working directory sorted by name)
- DataSetDir (default: "[DeploymentTree]\Environments\[SourceEnvironment]\Assets")
- ConvertedDataSetDir (default: "[DeploymentTree]\Environments\[DestinationEnvironment]\Assets")
- OptionSet

Optional parameters for -Deploy:
- Package or PackageDir (default: take all packages in current working directory sorted by name)
- Password (default: prompt for user input)

Steps for -Deploy (see -Step):
- Expand
- Convert
- Analyze
- Import

.EXAMPLE
dmtool -Build `
-Package                C:\packages\deployment_20120101-1.zip `
-SourceEnvironment      Development `
-DestinationEnvironment Test
-Pair                   "Development - Test" `
-TemplateDir            C:\dmtool\Templates `
-DataSetDir             C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Development\Assets `
-ConvertedDataSetDir    C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Test\Assets `
-OptionSet              MyImportOptions.xml

Build deployment operation files for deployment_20120101-1.zip
for deployment on Test with Development as source.

Creates:
C:\packages\deployment_20120101-1\AnalyzeDeployDataSet.xml
C:\packages\deployment_20120101-1\ConvertDeployDataSet.xml
C:\packages\deployment_20120101-1\ExpandDeployPackage.xml
C:\packages\deployment_20120101-1\ImportDeployDataSet.xml

.EXAMPLE
dmtool -Build `
-PackageDir             C:\packages `
-SourceEnvironment      Development `
-DestinationEnvironment Test
-Pair                   "Development - Test" `
-TemplateDir            C:\dmtool\Templates `
-DeploymentTree         C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData `
-DataSetDir             Environments\Development\Assets `
-ConvertedDataSetDir    Environments\Test\Assets

Build deployment operation files for all packages in C:\packages.

.EXAMPLE
dmtool -Deploy -Package deployment_20120101-1.zip -Password ***

Perform deployment operations for deployment_20120101-1.zip.

.EXAMPLE
dmtool -Deploy -PackageDir C:\packages -Password ***

Perform deployment operations for all packages in C:\packages.

.EXAMPLE
dmtool -Deploy

Perform deployment operations for all packages in current working directory and ask for password.

.LINK
Source repository:
https://github.com/RJK-Engineering/dmtool

Deployment operations reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm

Import options reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_mgr_command_line_importoptions_syntax.htm

#>

param (
    # Create deployment package.
    [switch]$Export,
    # Build deployment operation files.
    [switch]$Build,
    # Perform deployment operations.
    [switch]$Deploy,

    # Path to deployment package.
    # If no -Package or -PackageDir is provided, take all packages in current working directory sorted by name.
    [string]$Package,
    # Path to directory containing deployment packages.
    # If no -Package or -PackageDir is provided, take all packages in current working directory sorted by name.
    [string]$PackageDir,

    # Export Manifest.
    [string]$Manifest,

    # Source environment name.
    [string]$SourceEnvironment,
    # Destination environment name.
    [string]$DestinationEnvironment,
    # Source-destination pair name.
    # Default value: "[SourceEnvironment] - [DestinationEnvironment]"
    [string]$Pair,
    # Password. If not provided, prompt for user input.
    [string]$Password,

    # Path to existing import option XML.
    [string]$OptionSet,
    # DeploymentOption XML version.
    # Default value: "5.2.1"
    [string]$DeploymentOptionsVersion = "5.2.1",

    # Path to directory containing deployment operation file templates.
    # Default value: "[PSScriptRoot]\Templates",
    [string]$TemplateDir = "$PSScriptRoot\Templates",
    # Path to deployment data set directory. Relative paths will be appended to -DeploymentTree.
    # Default value: "[DeploymentTree]\Environments\[SourceEnvironment]\Assets")
    [string]$DataSetDir,
    # Path to converted deployment data set directory. Relative paths will be appended to -DeploymentTree.
    # Default value: "[DeploymentTree]\Environments\[DestinationEnvironment]\Assets")
    [string]$ConvertedDataSetDir,

    # Path to deployment manager executable.
    # Default value: "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\DeploymentManagerCmd"
    [string]$DeploymentManager = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\DeploymentManagerCmd",
    # Path to deployment tree.
    # Default value: "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData"
    [string]$DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData",
    # Deployment tree version.
    # Default value: "5.2.0"
    [string]$DeploymentTreeVersion = "5.2.0",

    # Name of file created by AnalyzeDeployDataSet operation.
    # File will be stored in converted deploy data set directory.
    [string]$AnalysisReportFileName = "ChangeImpactReport.xml",

    # Display help.
    [switch]$Help,
    # Log to "dmtool.log".
    [switch]$Log,
    # Log filename.
    [string]$LogFile = "dmtool.log",
    # Check configuration.
    [switch]$Check,
    # Do not make any changes.
    [switch]$Test,
    # Wait for user confirmation before executing Deployment Manager.
    [switch]$Confirm,

    # Execute specific -Deploy step. All steps will be executed if no -Step is specified.
    # The step name can be abbreviated, e.g. "I" for "Import", "E" for "Expand", "C" for "Convert", "A" for "Analyze".
    [string]$Step
)

if ($Help) {
    Get-Help $PSCommandPath -detailed
    exit
} elseif (! ($Export -or $Build -or $Deploy)) {
    "Use -Export, -Build, -Deploy or -Help."
    exit
}

# -Export
$ExportDeployDataSetXML = "ExportDeployDataSet.xml"
$CreateDeployPackageXML = "CreateDeployPackage.xml"

# -Build and -Deploy
$ExpandDeployPackageXML = "ExpandDeployPackage.xml"
$ConvertDeployDataSetXML = "ConvertDeployDataSet.xml"
$AnalyzeDeployDataSetXML = "AnalyzeDeployDataSet.xml"
$ImportDeployDataSetXML = "ImportDeployDataSet.xml"
$ImportOptionsXML = "ImportOptions.xml"

###########################################################

function GetPackages {
    if ($Package) {
        Get-Item $Package -ErrorAction Stop
        write-host "Package: $Package"
    } else {
        if (! $PackageDir) { $PackageDir = "." }
        $PackageDir = Resolve-Path $PackageDir -ErrorAction Stop

        $packages = Get-ChildItem $PackageDir -filter *.zip -ErrorAction Stop | Sort-Object
        if (! $packages) {
            write-host "No packages found in $PackageDir"
            exit
        }
        write-host "Found $($packages.count) package(s) in $PackageDir"
        $packages
    }
}

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
    "Created $out"
}

###########################################################

function ExportDeployDataSet( [string]$DeployDataSet ) {
    $deleteDestinationFilesOnError="true"

    $xml = GetXML $ExportDeployDataSetXML
    $el = $xml.DeploymentOperation.ExportDeployDataSet
    $el.deleteDestinationFilesOnError = $deleteDestinationFilesOnError
    $el.Environment = $SourceEnvironment
    $el.ExportManifest = $Manifest
    $el.DeployDataSet = $DeployDataSet

    WriteXML $xml $ExportDeployDataSetXML
}

function CreateDeployPackage( [string]$DeployDataSet, [string]$packagePath ) {
    $includeHalfMaps="true"
    $overwritePackage="true"

    $xml = GetXML $CreateDeployPackageXML
    $el = $xml.DeploymentOperation.CreateDeployPackage
    $el.includeHalfMaps = $includeHalfMaps
    $el.overwritePackage = $overwritePackage

    $el.Environment = $SourceEnvironment
    $el.DeployDataSet = $DeployDataSet
    $el.DeployPackage = $packagePath

    WriteXML $xml $CreateDeployPackageXML
}

function CreateExpandDeployPackageXML( [string]$packagePath ) {
    $createEnvironment="false"
    $halfMapMode="Overwrite" # options: Overwrite Merge LeaveAsIs

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
    $deleteDestinationFilesOnError="true"

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
    $el.Environment = $DestinationEnvironment
    $el.DeployDataSet = $ConvertedDeployDataSet
    # OptionSetPath will be set on deployment
    $null = $el.SelectNodes("OptionSetPath") | foreach { $_.ParentNode.RemoveChild($_) }

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

function Export {
    if (! (Test-Path $Manifest)) {
        "Export manifest not found"
        exit
    }
    $ManifestItem = Get-Item $Manifest -ErrorAction Stop
    $Manifest = $ManifestItem.FullName

    if (! $Package) {
        $Package = Join-Path (Get-Location) "$($ManifestItem.BaseName).zip"
    }

    $dir = Split-Path $Package -parent
    if (! (Test-Path $dir)) {
        "Directory does not exist: $dir"
        exit
    }
    $file = Split-Path $Package -leaf
    $baseName = $file -replace '\.\w+$'
    $xmlDir = "$dir\$baseName"

    "Package: $Package"
    "Environment: $SourceEnvironment"
    "Export manifest: $Manifest"
    $DeployDataSet = "$DataSetDir\$baseName"
    "Deploy data set: $DeployDataSet"


    if (Test-Path $Package) {
        "Package already exists"
        exit
    }

    if ($Test) { return }

    if (Test-Path $xmlDir) {
        Remove-Item $xmlDir -Recurse
        "Deleted $xmlDir"
    }
    if (Test-Path $Package) {
        Remove-Item $Package
        "Deleted $Package"
    }
    if (Test-Path $DeployDataSet) {
        Remove-Item $DeployDataSet -Recurse
        "Deleted $DeployDataSet"
    }

    if (-not (Test-Path $xmlDir)) {
        $null = mkdir $xmlDir -ErrorAction Stop
        "Created $xmlDir"
    }

    ExportDeployDataSet $DeployDataSet
    CreateDeployPackage $DeployDataSet $Package

    if (! $Password) {
        $Password = Read-Host -prompt "Password"
    }

    Run "$xmlDir\$ExportDeployDataSetXML" $Password
    Run "$xmlDir\$CreateDeployPackageXML"
}

function BuildOperationFiles( [System.IO.FileInfo]$pkg ) {
    "Processing $pkg ..."
    $packageName = $pkg.BaseName
    $DeployDataSet = "$DataSetDir\$packageName"
    "Deploy data set: $DeployDataSet"
    $ConvertedDeployDataSet = "$ConvertedDataSetDir\$packageName.converted"
    "Converted ddset: $ConvertedDeployDataSet"

    if ($Test) { return }

    $xmlDir = "$($pkg.Directory.FullName)\$($pkg.BaseName)"
    if (-not (Test-Path $xmlDir)) {
        $null = mkdir $xmlDir -ErrorAction Stop
        "Created $xmlDir"
    }

    CreateExpandDeployPackageXML $pkg.FullName
    CreateConvertDeployDataSetXML
    CreateAnalyzeDeployDataSetXML
    CreateImportDeployDataSetXML
    if ($OptionSet) {
        CreateOptionSetXML
    }
}

function Deploy( [System.IO.FileInfo]$pkg ) {
    $packageName = $pkg.BaseName
    $DeployDataSet = "$DataSetDir\$packageName"
    $ConvertedDeployDataSet = "$ConvertedDataSetDir\$packageName.converted"

    if (! $Test) {
        if (Test-Path $DeployDataSet) {
            Remove-Item $DeployDataSet -Recurse
            "Deleted $DeployDataSet"
        }
        if (Test-Path $ConvertedDeployDataSet) {
            Remove-Item $ConvertedDeployDataSet -Recurse
            "Deleted $ConvertedDeployDataSet"
        }
    }

    $xmlDir = "$($pkg.Directory.FullName)\$($pkg.BaseName)"
    if (-not (Test-Path $xmlDir)) {
        "Deployment operation file directory does not exist: $xmlDir"
        BuildOperationFiles $pkg
    }

    $path = "$xmlDir\$ExpandDeployPackageXML"
    SetDeployPackage $path $pkg.FullName
    if (! $Step -or $Step -like "E*") {
        Run $path
    }

    if (! $Step -or $Step -like "C*") {
        Run "$xmlDir\$ConvertDeployDataSetXML"
    }


    if (! $Step -or $Step -like "A*") {
        if (! $Password -and ! $Test) {
            $Password = Read-Host -prompt "Password"
        }
        Run "$xmlDir\$AnalyzeDeployDataSetXML" $Password
    }

    $importDeployDataSetPath = "$xmlDir\$ImportDeployDataSetXML"
    $optionSetPath = "$xmlDir\$ImportOptionsXML"
    if (Test-Path $optionSetPath) {
        SetOptionSet $importDeployDataSetPath $optionSetPath
    }
    if (! $Step -or $Step -like "I*") {
        if (! $Password -and ! $Test) {
            $Password = Read-Host -prompt "Password"
        }
        Run $importDeployDataSetPath $Password
    }
}

function Run( [string]$opFile, [string]$password ) {
    if ($Confirm) {
        "Starting $opfile, press enter to continue, ctrl+c to abort"
        Read-Host
    }
    if ($Test) {
        "& $DeploymentManager -o $opFile"
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

    $el = $xml.DeploymentOperation.ImportDeployDataSet
    $el.AppendChild($xml.CreateElement("OptionSetPath"))
    $el.OptionSetPath = $OptionSetPath

    try {
        $xml.Save($ImportDeployDataSetPath)
    } catch {
        $error[0].Exception
        exit
    }
}

function CheckLog( [string]$LogFilePath ) {
    $hasErrors = 0
    foreach ($line in Get-Content $LogFilePath) {
        if ($line -match "ERROR" `
            -and -not ( `
                $line -match "System Manager: Starting PCH Listener" `
            -or $line -match "System Manager: MAX_SOCKETS set to:" `
            -or $line -match "System Manager: PCH Listener started" `
            -or $line -match "System Manager: Registering my port" `
            -or $line -match "No interval found. Auditor disabled." `
            -or $line -match "System Manager: New socket connection detected. acceptSelector.keys"
        )) {
            "$line"
            $hasErrors = 1
        }
    }
    return $hasErrors
}

###########################################################

if ($Log -and -not $Check -and -not $Test) {
    Start-Transcript $LogFile
}

# Default paths
if (-not $DataSetDir) {
    $DataSetDir = "$DeploymentTree\Environments\$SourceEnvironment\Assets"
}
if (-not $ConvertedDataSetDir) {
    $ConvertedDataSetDir = "$DeploymentTree\Environments\$DestinationEnvironment\Assets"
}

# Check for relative paths and make absolute
foreach ($var in @("DataSetDir", "ConvertedDataSetDir")) {
    $path = (Get-Variable $var).value
    if ($path -and ! [System.IO.Path]::IsPathRooted($path)) {
        Set-Variable $var "$DeploymentTree\$path"
    }
}

# Default pair name
if (-not $Pair) {
    $Pair = "$SourceEnvironment - $DestinationEnvironment"
}

# Resolve paths
if ($TemplateDir) {
    $TemplateDir = Resolve-Path $TemplateDir -ErrorAction Stop
}
if ($OptionSet) {
    $OptionSet = Resolve-Path $OptionSet -ErrorAction Stop
}

foreach ($var in @(
    "Package", "PackageDir", "SourceEnvironment", "DestinationEnvironment", "Pair", "TemplateDir",
    "DeploymentTree", "DataSetDir", "ConvertedDataSetDir", "OptionSet", "AnalysisReportFileName"
)) {
    $value = (Get-Variable $var).value
    if ($value) { "{0,-23} {1}" -f "$var`:", $value }
}

if ($Check) {
    exit
} elseif ($Export) {
    Export
} else {
    $packages = GetPackages
    foreach ($pkg in $packages) {
        if ($Build) {
            BuildOperationFiles $pkg
        } elseif ($Deploy) {
            Deploy $pkg
        }
    }
}

"Done."

CheckLog $LogFile

if ($Log -and -not $Check -and -not $Test) {
    Stop-Transcript
    if (CheckLog $LogFile) {
        "`nTHERE WERE ERRORS !!!"
    }
}
