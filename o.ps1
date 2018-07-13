$settings = @{
    PackageDir = "P:\packages"
    TemplateDir = "P:\dmtool\Templates"
    DeploymentTree = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData"
    DataSetDir = "Environments\Ontwikkel\Assets"
    SourceEnvironment = "Ontwikkel"
}

& "$PSScriptRoot\dmtool.ps1" @args @settings
