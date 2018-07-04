$settings = @{
    PackageDir = "P:\packages"
    TemplateDir = "P:\dmtool\Templates"
    # OptionSetPath = "P:\packages\DM_Option_Set.xml"
    DataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\kiwi Ontwikkel (Nieuwe)\Assets"
    ConvertedDataSetDir = "C:\Programs\IBM\FileNet\ContentEngine\tools\deploy\P8DeploymentData\Environments\kiwi Test\Assets"
    SourceEnvironment = "kiwi Ontwikkel (Nieuwe)"
    Pair = "Ontwikkel (Nieuwe) - Test"
}

$dir = (Get-Item $PSCommandPath).Directory.FullName
& "$dir\dmtool.ps1" @args @settings
