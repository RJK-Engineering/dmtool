$settings = @{
    PackageDir = "P:\packages"
    TemplateDir = "P:\dmtool\Templates"
    # OptionSetPath = "P:\packages\DM_Option_Set.xml"
    DataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Ontwikkel\Assets"
    SourceEnvironment = "Ontwikkel"
    # ExportManifest = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\Ontwikkel\Assets\ExportManifests\123test.xml"
    ExportManifest = "P:\dmtool\123test.xml"
}

$dir = (Get-Item $PSCommandPath).Directory.FullName
& "$dir\dmtool.ps1" @args @settings
