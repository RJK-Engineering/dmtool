$settings = @{
    PackageDir = "P:\packages"
    TemplateDir = "P:\dmtool\Templates"
    DataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Ontwikkel\Assets"
    SourceEnvironment = "Ontwikkel"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings
