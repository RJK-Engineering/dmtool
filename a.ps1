$settings = @{
    TemplateDir = "$PSScriptRoot\Templates"
    DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData"
    DataSetDir = "Environments\kiwi Test\Assets"
    ConvertedDataSetDir = "Environments\PROD\Assets"
    SourceEnvironment = "kiwi Test"
    DestinationEnvironment = "PROD"
    Pair = "Test to Prod"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings
