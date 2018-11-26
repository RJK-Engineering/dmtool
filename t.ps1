$settings = @{
    TemplateDir = "$PSScriptRoot\Templates"
    DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData"
    DataSetDir = "Environments\Ontwikkel\Assets"
    ConvertedDataSetDir = "Environments\Test\Assets"
    SourceEnvironment = "Ontwikkel"
    DestinationEnvironment = "Test"
    Pair = "Ontw to Test"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings -Log
