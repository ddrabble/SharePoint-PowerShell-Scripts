<# 
.Synopsis
    Sets Output Cache on Site Collection.
    
.Description
    Sets Output Cache on Site Collection with the Publishing Web Feature Enabled.
    
.Parameter SiteCollection ("site")
    The Site Collection object to set the Output Cache
    
.Parameter AnonymousCacheProfileID ("anonymousProfileID")
    The ID of the Anonymous Cache Profile. Defaults to 1 ("Disabled"). 

.Parameter AuthenticatedCacheProfileID ("authenticatedProfileID")
    The ID of the Authenticated Cache Profile. Defaults to 1 ("Disabled").

.Parameter PublishingSites ("publishing")
    Sets the option for Publishing site to use a different page output cache profile.

.Parameter PageLayouts
    Sets the option for Page Layouts to use a different page output cache profile. If PageLayouts and PublishingSites
    are both set, then the PageLayout cache will override and take precendence. 

.Parameter DebugInfo
    Sets the Debug Cache Information on pages. This includes the date and time that page contents were last rendered.

.Parameter EnableOutputCache ("Enable")
    Enables the Output cache.

.Parameter DisableOutputCache ("Disable")
    Disables the Output cache and resets everything to the SharePoint default settings.

.Parameter FlushBlobCache ("blobCache")
    Sets the flag to flush the Blob Cache

.Parameter ObjectCacheSize ("size")
    Sets the maximum size of the object cache in gigabytes (GB). Defaults to 10.
    
.Example
    To enable everything, set Profiles, Object Cache size to 50, do..
    Set-SPSiteOutputCache (Get-SPSite http://domain.com) -AnonymousCacheProfileID 2 -AuthenticatedCacheProfileID 3 -PublishingSites -PageLayouts -DebugInfo -Enable -FlushBlobCache -ObjectCacheSize 50 {-Verbose}

.Example
    To disable output cache.
    Set-SPSiteOutputCache (Get-SPSite http://domain.com) -Disable {-Verbose}

.Example
    To enable output cache only
    Set-SPSiteOutputCache (Get-SPSite http://domain.com) -Enable {-Verbose}

.Example
    To set a custom cache profile for authenticated users for each site collection.
    Get-SPSite | Set-SPSiteOutputCache -AuthenticatedCacheProfileID 4 -PublishingSites -PageLayouts -DebugInfo -Enable -FlushBlobCache  {-Verbose}

.Link Configure cache settings for a web application in SharePoint Server 2013
    https://technet.microsoft.com/en-us/library/cc770229.aspx

.Link Cache settings operations in SharePoint Server 2013
    https://technet.microsoft.com/en-us/library/cc261797.aspx

.Notes
    Name:      Set-SPSiteOutputCache
    Author:    Travis Smith
    LastEdit:  05/05/2014  

#>

function Set-SPSiteOutputCache()
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SiteCollection")]
        [Microsoft.SharePoint.SPSite]
        $site,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("AnonymousCacheProfileID")]
        [System.Int32]
        $anonymousProfileID = 1,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("AuthenticatedCacheProfileID")]
        [System.Int32]
        $authenticatedProfileID = 1,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("PublishingSites")]
        [Switch]
        $publishing,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $PageLayouts,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $DebugInfo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("EnableOutputCache")]
        [Switch]
        $Enable,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("DisableOutputCache")]
        [Switch]
        $Disable,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("FlushBlobCache")]
        [Switch]
        $blobCache,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("ObjectCacheSize")]
        [System.Int32]
        $size = 10
    )
    BEGIN {
        $updateRequired = $false
        if ($Enable -and $Disable)
        {
            throw("You cannot both enable and disable output cache")
        }
    }
    PROCESS {
        Write-Verbose "Checking to see if $($site.Url) is a Publishing Web"
        if ([Microsoft.SharePoint.Publishing.PublishingWeb]::IsPublishingWeb($site.RootWeb))
        {
            Write-Verbose "$($site.Url) is a Publishing Web"
            $cacheSettings = new-object Microsoft.SharePoint.Publishing.SiteCacheSettingsWriter($site.Url);
            
            if(($Enable.IsPresent -and $Enable -eq $false ) -or $Disable)
            {
                Write-Verbose "Disabling Cache on $($site.Url)"
                if($cacheSettings.EnableCache -eq $true)
                {
                    $cacheSettings.EnableCache = $false;
                    $cacheSettings.SetAnonymousPageCacheProfileId($site, 1);
                    $cacheSettings.SetAuthenticatedPageCacheProfileId($site, 1);
                    $cacheSettings.AllowLayoutPageOverrides = $false
                    $cacheSettings.AllowPublishingWebPageOverrides = $false
                    $cacheSettings.EnableDebuggingOutput = $false
                    $cacheSettings.ObjectCacheSize = $size
                    $cacheSettings.Update()

                    Write-Verbose "De-activated output cache on site $($site.Url)"
                   
                }
                else
                {
                    Write-Verbose "Output cache already de-actived on site $($site.Url)"
                }
            }
            else
            {
                Write-Verbose "Enabling cache on $($site.Url)"
                Write-Verbose "Checking to see if Cache is already enabled on $($site.Url)"
                if($cacheSettings.EnableCache -eq $false)
                {
                    Write-Verbose "Enabling Cache for $($site.Url)"

                    $cacheSettings.EnableCache = $true;     
                    $cacheSettings.SetAnonymousPageCacheProfileId($site, $anonymousProfileID)
                    $cacheSettings.SetAuthenticatedPageCacheProfileId($site, $authenticatedProfileID)
                    $cacheSettings.AllowLayoutPageOverrides = $PageLayouts
                    $cacheSettings.AllowPublishingWebPageOverrides = $publishing
                    $cacheSettings.EnableDebuggingOutput = $debugInfo
                    $cacheSettings.SetFarmCacheFlushFlag();
                    if ($blobCache)
                    {
                        $cacheSettings.SetFarmBlobCacheFlushFlag();
                    }                
                    $cacheSettings.Update();

                    Write-Verbose "Activated output cache on site $site"
                }
                else
                {
                    Write-Verbose "Output cache already active on site $site"
                    Write-Verbose "Checking Cache Settings for Requested Changes for $($site.Url)"
                    if($cacheSettings.GetAnonymousPageCacheProfileId($site) -ne $anonymousProfileID)
                    {
                        $updateRequired = $true
                        $cacheSettings.SetAnonymousPageCacheProfileId($site, $anonymousProfileID)
                        Write-Verbose "Anonymous Page Cache Profile change requested"
                    }

                    if($cacheSettings.GetAuthenticatedPageCacheProfileId($site) -ne $authenticatedProfileID)
                    {
                        $updateRequired = $true
                        $cacheSettings.SetAuthenticatedPageCacheProfileId($site, $authenticatedProfileID);
                        Write-Verbose "Authenticated Page Cache Profile change requested"
                    }

                    if($cacheSettings.AllowLayoutPageOverrides -ne $PageLayouts)
                    {
                        $updateRequired = $true
                        $cacheSettings.AllowLayoutPageOverrides = $PageLayouts
                        Write-Verbose "Allow Page Layouts Over-ride Policy change requested"
                    }
                    if($cacheSettings.AllowPublishingWebPageOverrides -ne $publishing)
                    {
                        $updateRequired = $true
                        $cacheSettings.AllowPublishingWebPageOverrides = $publishing
                        Write-Verbose "Allow Publishing Site Over-ride Policy change requested"
                    }

                    if($cacheSettings.EnableDebuggingOutput -ne $debugInfo)
                    {
                        $updateRequired = $true
                        $cacheSettings.EnableDebuggingOutput = $debugInfo
                        Write-Verbose "Debug Cache Information change requested"
                    }

                    if($blobCache)
                    {
                        $updateRequired = $true
                        $cacheSettings.SetFarmBlobCacheFlushFlag();
                        Write-Verbose "Blob Cache Flush change requested"
                    }

                    if($updateRequired)
                    {
                        Write-Verbose "Updating Cache for requested changes"
                        $cacheSettings.Update();
                    }

                }
            }
        }
        else
        {
            Write-Host "PublishingWeb Feature is not activated." -ForegroundColor Red
            Write-Host "To use the page output cache and the associated cache profile settings, you must be using the Publishing feature on your site." -ForegroundColor Red
            Write-Host "Please activate the site collection's SharePoint Server Publishing Infrastructure ('PublishingSite') feature ('f6924d36-2fa8-4f0b-b16d-06b7250180fa') and the site's PublishingWeb feature ('94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb') if you want to use Output Cache." -ForegroundColor Red
        }
    }
    END {
        Write-Host "Done."  -ForegroundColor Green
        $site.Dispose();
    }
}

function Get-AnonymousCacheProfileID
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Microsoft.SharePoint.SPSite]
        $Site,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Url,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Microsoft.SharePoint.Publishing.SiteCacheSettingsWriter]
        [Alias("SiteCacheSettingsWriter")]
        $cacheSettings
    )
    BEGIN {
        $disposeSite = $false
        if (!$Url -and !$Site)
        {
            throw("Missing at least one parameter -Site or -Url")
        }

        if ($Url -and !$Site)
        {
            $Site = Get-SPSite $Url
            $disposeSite = $true
        }

        if (!$Url -and $Site)
        {
            $Url = $Site.Url
        }

        if (!$cacheSettings)
        {
            $cacheSettings = new-object Microsoft.SharePoint.Publishing.SiteCacheSettingsWriter($Url);
        }
    }
    PROCESS {
        $ID = $cacheSettings.GetAnonymousPageCacheProfileId($Site)
    }
    END {
        if ($disposeSite)
        {
            $Site.Dispose()
        }

        Return $ID
    }
}

function Get-GetAuthenticatedCacheProfileID
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Microsoft.SharePoint.SPSite]
        $Site,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Url,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Microsoft.SharePoint.Publishing.SiteCacheSettingsWriter]
        [Alias("SiteCacheSettingsWriter")]
        $cacheSettings
    )
    BEGIN {
        $disposeSite = $false
        if (!$Url -and !$Site)
        {
            throw("Missing at least one parameter -Site or -Url")
        }

        if ($Url -and !$Site)
        {
            $Site = Get-SPSite $Url
            $disposeSite = $true
        }

        if (!$Url -and $Site)
        {
            $Url = $Site.Url
        }

        if (!$cacheSettings)
        {
            $cacheSettings = new-object Microsoft.SharePoint.Publishing.SiteCacheSettingsWriter($Url);
        }
    }
    PROCESS {
        $ID = $cacheSettings.GetAuthenticatedPageCacheProfileId($Site)
    }
    END {
        if ($disposeSite)
        {
            $Site.Dispose()
        }

        Return $ID
    }
}