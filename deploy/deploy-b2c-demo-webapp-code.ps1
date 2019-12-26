param (
    [Parameter(Mandatory=$True)][Alias('r')][string]$ResourceGroupName = "",
    [Parameter(Mandatory=$True)][Alias('n')][string]$WebAppName = ""
)

Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $WebAppName -ArchivePath .\WebApp.zip -Force
