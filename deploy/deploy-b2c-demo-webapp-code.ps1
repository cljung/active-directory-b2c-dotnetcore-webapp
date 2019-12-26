param (
    [Parameter(Mandatory=$True)][Alias('r')][string]$ResourceGroupName = "",
    [Parameter(Mandatory=$True)][Alias('n')][string]$WebAppName = "",
    [Parameter(Mandatory=$True)][Alias('p')][string]$ArchivePath = ""    
)

write-host "Deploying $ArchivePath to $WebAppName..."
Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $WebAppName -ArchivePath $ArchivePath -Force
