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
- ExportManifest
- DataSetDir
Optional:
- Package (if not provided: create package in current working directory using name of ExportManifest)
- Password (if not provided: prompt for user input)

Required parameters for -Build:
- TemplateDir
- DataSetDir
- SourceEnvironment
- DestinationEnvironment
- Pair
Optional:
- Package or PackageDir
- ConvertedDataSetDir (if not provided: DataSetDir value)
- OptionSet

Optional parameters for -Deploy:
- Package or PackageDir
- Password (if not provided: prompt for user input)

.EXAMPLE
dmtool -Build `
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
dmtool -Build `
-PackageDir "C:\packages" `
-SourceEnvironment "Development" `
-Pair "Development - Test" `
-TemplateDir "C:\dmtool\Templates" `
-DataSetDir "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Development\Assets" `
-ConvertedDataSetDir "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Test\Assets"

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
    [string]$Package,
    # Path to directory containing deployment packages.
    [string]$PackageDir,

    # Export Manifest.
    [string]$ExportManifest,

    # Source environment name.
    [string]$SourceEnvironment,
    # Destination environment name.
    [string]$DestinationEnvironment,
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
    [switch]$Help,
    # Do not make any changes.
    [switch]$Test,
    # Wait for user confirmation before executing Deployment Manager.
    [switch]$Confirm
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

# -Build
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
    $deleteDestinationFilesOnError="false"

    $xml = GetXML $ExportDeployDataSetXML
    $el = $xml.DeploymentOperation.ExportDeployDataSet
    $el.deleteDestinationFilesOnError = $deleteDestinationFilesOnError
    $el.Environment = $SourceEnvironment
    $el.ExportManifest = $ExportManifest
    $el.DeployDataSet = $DeployDataSet

    WriteXML $xml $ExportDeployDataSetXML
}

function CreateDeployPackage( [string]$DeployDataSet, [string]$packagePath ) {
    $includeHalfMaps="false"
    $overwritePackage="false"

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
    $halfMapMode="LeaveAsIs"

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
    $el.Environment = $DestinationEnvironment
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

function Export {
    if (! (Test-Path $ExportManifest)) {
        "Export manifest not found"
        exit
    }
    $ExportManifestItem = Get-Item $ExportManifest -ErrorAction Stop

    if (! $Package) {
        $Package = Join-Path (Get-Location) "$($ExportManifestItem.BaseName).zip"
    }
    if (Test-Path $Package) {
        "Package already exists"
        exit
    }

    $dir = Split-Path $Package -parent
    if (! (Test-Path $dir)) {
        "Directory does not exist: $dir"
        exit
    }
    $file = Split-Path $Package -leaf
    $baseName = $file -replace '\.\w+$'

    "Package: $Package"
    "Environment: $SourceEnvironment"
    "Export manifest: $ExportManifest"
    $DeployDataSet = "$DataSetDir\$baseName"
    "Deploy data set: $DeployDataSet"

    if ($Test) { return }

    $xmlDir = "$dir\$baseName"
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
    $xmlDir = "$($pkg.Directory.FullName)\$($pkg.BaseName)"
    if (-not (Test-Path $xmlDir)) {
        "Deployment operation file directory does not exist: $xmlDir"
    }

    $path = "$xmlDir\$ExpandDeployPackageXML"
    SetDeployPackage $path $pkg.FullName
    Run $path

    Run "$xmlDir\$ConvertDeployDataSetXML"

    if (! $Password -and ! $Test) {
        $Password = Read-Host -prompt "Password"
    }

    Run "$xmlDir\$AnalyzeDeployDataSetXML" $Password

    $importDeployDataSetPath = "$xmlDir\$ImportDeployDataSetXML"
    $optionSetPath = "$xmlDir\$ImportOptionsXML"
    if (Test-Path $optionSetPath) {
        SetOptionSet $importDeployDataSetPath $optionSetPath
    }
    Run $importDeployDataSetPath $Password
}

function Run( [string]$opFile, [string]$password ) {
    if ($Confirm) {
        "Starting $opfile, press enter to continue, ctrl+c to abort"
        Read-Host
    }
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

if ($Export) {
    Export
} else {
    $packages = GetPackages
    if ($Build) {
        $TemplateDir = Resolve-Path $TemplateDir -ErrorAction Stop
        "Template directory: $TemplateDir"
        "Deployment tree: $DeploymentTree"
        "Analysis report: $AnalysisReportFileName"

        if ($OptionSet) {
            $OptionSet = Resolve-Path $OptionSet -ErrorAction Stop
            "Option set: $OptionSet"
        # } else {
        #     $OptionSet = Resolve-Path "$TemplateDir\$ImportOptionsXML"
        }
        "Source environment: $SourceEnvironment"
        "Destination environment: $DestinationEnvironment"
        "Source-destination pair: $Pair`n"

        $action = "BuildOperationFiles"
    } else {
        $action = "Deploy"
    }

    foreach ($pkg in $packages) {
        & $action $pkg
    }
}

"Done."
