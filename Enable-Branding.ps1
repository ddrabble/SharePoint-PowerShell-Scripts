<#
.SYNOPSIS
    Enables the Branding Feature for a SP Web. 

.DESCRIPTION
    Enables the Branding Feature for a SP Web. 

.NOTES
    File Name: Enable-Branding.ps1
    Author   : Travis Smith
    Version  : 1.0

.PARAMETER Url
    Specifies the URL of the Web Site for which the Branding Feature should be enabled. 
	 

.EXAMPLE
    PS > .\Enable-Branding.ps1 -Url http://intranet.example.com

   Description
   -----------
   This script enables the Branding Featuree for the http://intranet.example.com.
#>
param( 
   [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)] 
   [string]$Url
) 

# Site collection branding feature ID
$brandingFeatureId = [GUID]"31032355-50a8-4e5a-9955-0abd1693b108"

$web = Get-SPWeb $url

# -------------------------------------------------------- 
# SCRIPT
# -------------------------------------------------------- 

# Add the SharePoint PowerShell snap-in
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue


function MaybeActivatWebFeature($ID, $name)
{

    Write-Host "Checking $($web.Url) for Web Feature $($name)"
    if ($web.Features[$ID] -eq $null) 
	{
        Write-Host "Enabling Feature $($name)"
        Enable-SPFeature -identity $ID -URL $web.Url -Force
	}
    else
    {
        Write-Host "Feature already activated"
    }
}


            
# Check if Cross-Farm Site Permissions is activated, if not, activate it
MaybeActivatWebFeature "94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb" "Web Cross-Farm Site Permissions"
            
# Publishing Web
MaybeActivatWebFeature "22A9EF51-737B-4ff2-9346-694633FE4416" "Publishing Web"

# Check if Branding is activated, if not, activate it
MaybeActivatWebFeature $brandingFeatureId "Branding"

$web.dispose();


# -------------------------------------------------------- 
# END SCRIPT
# -------------------------------------------------------- 