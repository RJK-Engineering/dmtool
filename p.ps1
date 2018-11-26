$settings = @{
    TemplateDir = "$PSScriptRoot\Templates"
    DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData"
    DataSetDir = "Environments\Ontwikkel\Assets"
    ConvertedDataSetDir = "Environments\PROD\Assets"
    SourceEnvironment = "Ontwikkel"
    DestinationEnvironment = "PROD"
    Pair = "Ontw to Prod"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings -Log
