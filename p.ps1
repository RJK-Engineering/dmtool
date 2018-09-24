$settings = @{
    TemplateDir = "$PSScriptRoot\Templates"
    DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData"
    DataSetDir = "Environments\kiwi Ontwikkel (Nieuwe)\Assets"
    ConvertedDataSetDir = "Environments\kiwi Productie\Assets"
    SourceEnvironment = "kiwi Ontwikkel (Nieuwe)"
    DestinationEnvironment = "kiwi Productie"
    Pair = "Ontwikkel (Nieuwe) - Test"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings
