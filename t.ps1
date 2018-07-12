$settings = @{
    PackageDir = "P:\packages"
    TemplateDir = "P:\dmtool\Templates"
    DataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\kiwi Ontwikkel (Nieuwe)\Assets"
    ConvertedDataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\kiwi Test\Assets"
    SourceEnvironment = "kiwi Ontwikkel (Nieuwe)"
    DestinationEnvironment = "kiwi Test"
    Pair = "Ontwikkel (Nieuwe) - Test"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings
