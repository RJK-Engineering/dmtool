<#

.SYNOPSIS
IBM Deployment Manager tool.

.DESCRIPTION
Build IBM Deployment Manager deployment operation files and perform the
operations they specify using the command-line interface.

.EXAMPLE
.\dmtool.ps1 -build
Build deployment operation files.

.EXAMPLE
.\dmtool.ps1 -deploy
Perform deployment operations.

.NOTES
Deployment operations reference:
https://www.ibm.com/support/knowledgecenter/SSNW2F_5.2.1/com.ibm.p8.common.deploy.doc/deploy_operation_formats.htm

.LINK
https://github.com/RJK-Engineering/dmtool

#>

param (
    # Build deployment operation files.
    [switch]$Build = $false,
    # Perform deployment operations.
    [switch]$Deploy = $false,

    # Path to deployment package.
    [string]$Package = $null,
    # Path to directory containing deployment packages.
    [string]$PackageDir = $null,
    # Path to directory containing deployment operation file templates.
    [string]$TemplateDir = $null,

    # Path to deployment data set directory.
    [string]$DataSetDir = $null,
    # Path to converted deployment data set directory.
    # Default value: -DataSetDir parameter value
    [string]$ConvertedDataSetDir = $($DataSetDir),

    # Source environment name.
    [string]$SourceEnvironment = $null,
    # Source-destination pair name.
    [string]$Pair = $null,

    # Path to deployment manager executable.
    # Default value: C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\DeploymentManager.exe
    [string]$DeploymentManager = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\DeploymentManager.exe",
    # Path to deployment tree.
    # Default value: C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData
    [string]$DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData",
    # Deployment tree version.
    [string]$DeploymentTreeVersion = "5.2.0",
    # Path to option set.
    # Default value: 5.2.0
    [string]$OptionSet = $null,
    # Option set version.
    # Default value: 5.2.1
    [string]$OptionSetVersion = "5.2.1",

    # Name of file created by AnalyzeDeployDataSet operation.
    # File will be stored in converted deploy data set directory.
    [string]$AnalysisReportFileName = "ChangeImpactReport.xml",

    # Name of ExpandDeployPackage deployment operation file
    # Default value: ExpandDeployPackage.xml
    [string]$ExpandDeployPackageXML = "ExpandDeployPackage.xml",
    # Name of ConvertDeployDataSet deployment operation file
    # Default value: ConvertDeployDataSet.xml
    [string]$ConvertDeployDataSetXML = "ConvertDeployDataSet.xml",
    # Name of AnalyzeDeployDataSet deployment operation file
    # Default value: AnalyzeDeployDataSet.xml
    [string]$AnalyzeDeployDataSetXML = "AnalyzeDeployDataSet.xml",
    # Name of ImportDeployDataSet deployment operation file
    # Default value: ImportDeployDataSet.xml
    [string]$ImportDeployDataSetXML = "ImportDeployDataSet.xml"
)

if ($Build) {
} elseif ($Deploy) {
    "deploy"
    exit
} else {
    Get-Help .\dmtool.ps1
    exit
}

###########################################################

function GetXML( [string]$file ) {
    Write-Host "Generating $file ..."
    [xml]$xml = Get-Content -Path "$TemplateDir\$file"
    $el = $xml.DeploymentOperation
    $el.deploymentTreeLocation = $DeploymentTree
    $el.version = $DeploymentTreeVersion
    return $xml
}

function WriteXML( [xml]$xml, [string]$file ) {
    $out = "$xmlDir\$file"
    $xml.Save($out)
    "Written $out"
}

function ExpandDeployPackage( [string]$packagePath ) {
    $xml = GetXML $ExpandDeployPackageXML

    $createEnvironment="false"
    $halfMapMode="merge"

    $el = $xml.DeploymentOperation.ExpandDeployPackage
    $el.createEnvironment = $createEnvironment
    $el.halfMapMode = $halfMapMode

    $el.Environment = $SourceEnvironment
    $el.DeployDataSet = $DeployDataSet
    $el.DeployPackage = $packagePath

    WriteXML $xml $ExpandDeployPackageXML
}

function ConvertDeployDataSet {
    $xml = GetXML $ConvertDeployDataSetXML

    $deleteDestinationFilesOnError="false"

    $el = $xml.DeploymentOperation.ConvertDeployDataSet
    $el.deleteDestinationFilesOnError = $deleteDestinationFilesOnError

    $el.Pair = $Pair
    $el.SourceDeployDataSet = $DeployDataSet
    $el.ConvertedDeployDataSet = $ConvertedDeployDataSet

    WriteXML $xml $ConvertDeployDataSetXML
}

function AnalyzeDeployDataSet {
    $xml = GetXML $AnalyzeDeployDataSetXML

    $analysisFailuresLimit="100" # default: 100
    $deleteAnalysisResultsFileOnError="false"
    $importUpdateOption="UpdateAlways" # options: UpdateIfNewer UpdateAlways UpdateNotAllowed
    $generateDetailedReport="true"

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

function ImportDeployDataSet {
    $xml = GetXML $ImportDeployDataSetXML

    $el = $xml.DeploymentOperation.ImportDeployDataSet
    $el.Environment = $SourceEnvironment
    $el.DeployDataSet = $ConvertedDeployDataSet
    $el.OptionSetPath = $OptionSet

    WriteXML $xml $ImportDeployDataSetXML
}

###########################################################

"Package directory: $PackageDir"
"Template directory: $TemplateDir"
"Deployment tree: $DeploymentTree"
"Analysis report: $AnalysisReportFileName"
"Option set: $OptionSet"

"Source environment: $SourceEnvironment"
"Source-destination pair: $Pair"; ""

function ProcessPackage($pkg) {
    "Processing $pkg ..."
    $packageName = $pkg.BaseName
    $DeployDataSet = "$DataSetDir\$packageName"
    "Deploy data set: $DeployDataSet"
    $ConvertedDeployDataSet = "$ConvertedDataSetDir\$packageName.converted"
    "Converted ddset: $ConvertedDeployDataSet"

    $xmlDir = "$PackageDir\$packageName"
    if (-not (Test-Path $xmlDir)) {
        "Creating $xmlDir ..."
        $null = mkdir $xmlDir
    }

    ""; ExpandDeployPackage($pkg.FullName); ""
    ConvertDeployDataSet; ""
    AnalyzeDeployDataSet; ""
    ImportDeployDataSet; ""
}

if ($Package) {
    $pkg = Get-Item $Package
    if (! $pkg) { exit }
    ProcessPackage($pkg)
} else {
    $packages = Get-ChildItem $PackageDir -filter *.zip
    if (! $packages) { exit }
    "Found $($packages.count) package(s) in $PackageDir"; ""
    foreach ($pkg in $packages) {
        ProcessPackage($pkg)
    }
}

"Done."
