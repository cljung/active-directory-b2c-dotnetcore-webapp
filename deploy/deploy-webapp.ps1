param (
    [Parameter(Mandatory=$True)][Alias('r')][string]$ResourceGroupName = "",
    [Parameter(Mandatory=$True)][Alias('n')][string]$WebAppName = "",
    [Parameter(Mandatory=$True)][Alias('p')][string]$AppServicePlan = "",
    [Parameter(Mandatory=$True)][Alias('l')][string]$Location = "",
    [Parameter(Mandatory=$False)][Alias('t')][string]$Tier = "Free",
    [Parameter(Mandatory=$False)][Alias('o')][bool]$AlwaysOn=$False,
    [Parameter(Mandatory=$False)][Alias('a')][string]$AppInsightsName = "",
    [Parameter(Mandatory=$False)][Alias('c')][hashtable] $ConfigParams = $null
)

$ErrorActionPreference = "Stop"    

$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ( $null -eq $rg) {
    write-host "Creating ResourceGroup $ResourceGroupName in $Location"
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $location
    $Location = $rg.Location
}

$plan = Get-AzAppServicePlan -Name $AppServicePlan -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if ( $null -eq $plan ) {
    write-host "Creating AppServicePlan $AppServicePlan"
    $plan = New-AzAppServicePlan -Name $AppServicePlan -Location $location -ResourceGroupName $ResourceGroupName -Tier $Tier
}

$webapp = Get-AzWebApp -Name $WebAppName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
if ( $null -eq $webapp ) {
    write-host "Creating AppService $WebAppName"
    $webapp = New-AzWebApp -ResourceGroupName $ResourceGroupName -AppServicePlan $AppServicePlan -Name $WebAppName
    write-host "Setting AppService runtime to .Net Core"
    New-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Web/sites/config" -ResourceName "$WebAppName/metadata" -ApiVersion 2018-02-01 -Force -PropertyObject @{"CURRENT_STACK"="dotnetcore"}
    $app = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Web/sites" -Name $webAppName
    if( $app.Properties.httpsOnly -eq $False)
    {
        write-host "Setting AppService HTTPS only"
        $app.Properties.httpsOnly = $True
        $app | Set-AzResource -Force
    }
}

# copy current appsettings to a hastable so we can edit/add and set new ones
$appSettings = $webapp.SiteConfig.AppSettings
$newAppSettings = @{}
ForEach ($item in $appSettings) {
    $newAppSettings[$item.Name] = $item.Value
}

if( $AppInsightsName -ne '') {
    $AppInsights = Get-AzApplicationInsights | Where-Object {$_.Name -eq $AppInsightsName}
    if( $AppInsights.Count -ne 0 ) 
    {
        Write-Host "Adding ApplicationInsights $AppInsightsName..."
        $newAppSettings["APPINSIGHTS_INSTRUMENTATIONKEY"] = $AppInsights.InstrumentationKey
        $newAppSettings["APPINSIGHTS_PROFILERFEATURE_VERSION"] = "1.0.0"
        $newAppSettings["ApplicationInsightsAgent_EXTENSION_VERSION"] ="~2"
    
    }
}

if ( $null -ne $ConfigParams ) {
    ForEach ($item in $ConfigParams.GetEnumerator() ) {
        write-host "Setting ConfigParam " $item.Key
        $newAppSettings[$item.Key] = $item.Value
    }
    <# create $ConfigPArams as a hashtable like below
       $ConfigParams = @{ "param1" = "value1"; "param2" = "value2"; "param3" = "value3"; }
    #>
}

Set-AzWebApp -Name $WebAppName -ResourceGroupName $ResourceGroupName -AppSettings $newAppSettings

if ( $True -eq $AlwaysOn ) {
    write-host "Setting AlwaysOn to True..."
    $webapp = Get-AzWebApp -Name $WebAppName -ResourceGroupName $ResourceGroupName
    $webapp.SiteConfig.AlwaysOn = $AlwaysOn
    $webapp | Set-AzWebApp
}

