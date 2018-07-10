$settings = @{
    PackageDir = "P:\packages"
    TemplateDir = "P:\dmtool\Templates"
    DataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Ontwikkel\Assets"
    SourceEnvironment = "Ontwikkel"
}

$dir = (Get-Item $PSCommandPath).Directory.FullName
& "$dir\dmtool.ps1" @args @settings
