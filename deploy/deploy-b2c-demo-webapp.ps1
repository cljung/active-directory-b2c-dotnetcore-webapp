param (
    [Parameter(Mandatory=$True)][Alias('r')][string]$ResourceGroupName = "",
    [Parameter(Mandatory=$True)][Alias('n')][string]$WebAppName = "",
    [Parameter(Mandatory=$True)][Alias('p')][string]$AppServicePlan = "",
    [Parameter(Mandatory=$True)][Alias('l')][string]$Location = "",
    [Parameter(Mandatory=$False)][Alias('t')][string]$Tier = "Free",
    [Parameter(Mandatory=$False)][Alias('a')][string]$AppInsightsName = "",
    [Parameter(Mandatory=$True)][Alias('b')][string]$B2CTenant = "",
    [Parameter(Mandatory=$True)][Alias('i')][string]$B2CAppId = "",
    [Parameter(Mandatory=$True)][Alias('k')][string]$B2CAppKey = "",
    [Parameter(Mandatory=$True)][string]$B2CApiName = "",
    [Parameter(Mandatory=$False)][string]$SignInPolicyId = "B2C_1A_signin",
    [Parameter(Mandatory=$False)][string]$SignUpPolicyId = "B2C_1A_signup",
    [Parameter(Mandatory=$False)][string]$ForgotPasswordPolicyId = "B2C_1A_ForgotPassword",
    [Parameter(Mandatory=$False)][string]$ResetPasswordPolicyId = "B2C_1A_PasswordReset",
    [Parameter(Mandatory=$False)][string]$SignUpSignInPolicyId = "B2C_1A_signin",
    [Parameter(Mandatory=$False)][string]$EditProfilePolicyId = "B2C_1A_ProfileEdit",
    [Parameter(Mandatory=$False)][string]$CfgEnv = "Dev"
)

$AlwaysOn = $False

if ( $B2CTenant -imatch ".onmicrosoft.com" ) {
    $B2CTenant = $B2CTenant.Replace(".onmicrosoft.com", "")
}

$ConfigParams = @{ "Authentication:AzureAdB2C-Config" = $CfgEnv; 
 "Authentication:$($CfgEnv):Tenant" = "$B2CTenant.onmicrosoft.com";
 "Authentication:$($CfgEnv):AzureAdB2CInstance" = "https://$B2CTenant.b2clogin.com/tfp";
 "Authentication:$($CfgEnv):ApiScopes" = "https://$B2CTenant.onmicrosoft.com/$B2CApiName/demo.read";
 "Authentication:$($CfgEnv):ApiUrl" = "https://$B2CApiName.azurewebsites.net/hello";
 "Authentication:$($CfgEnv):ClientId" = $B2CAppId;
 "Authentication:$($CfgEnv):ClientSecret" = $B2CAppKey;
 "Authentication:$($CfgEnv):RedirectUri" = "https://$WebAppName.azurewebsites.net/signin-oidc";
 "Authentication:$($CfgEnv):EditProfilePolicyId" = $EditProfilePolicyId;
 "Authentication:$($CfgEnv):ForgotPasswordPolicyId" = $ForgotPasswordPolicyId;
 "Authentication:$($CfgEnv):ResetPasswordPolicyId" = $ResetPasswordPolicyId;
 "Authentication:$($CfgEnv):SignInPolicyId" = $SignInPolicyId;
 "Authentication:$($CfgEnv):SignUpPolicyId" = $SignUpPolicyId;
 "Authentication:$($CfgEnv):SignUpSignInPolicyId" = $SignInPolicyId;
}

#$ConfigParams

.\deploy-webapp.ps1 -r $ResourceGroupName -n $WebAppName -p $AppServicePlan -l $Location -t $Tier -o $AlwaysOn -a $AppInsightsName -c $ConfigParams
