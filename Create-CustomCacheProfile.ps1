<#
.Synopsis
    Sets Output Cache on Site Collection.
    
.Description
    Sets Output Cache on Site Collection with the Publishing Web Feature Enabled.
    
.Parameter Title (required)

.Parameter Name
    Display name is used to populate the list of available cache profiles for site owners and page layout owners.

.Parameter Description
    Display description is used to populate the list of available cache profiles for site owners and page layout owners.

.Parameter ACLCheck
    Perform ACL Check ensures that all items in the cache are appropriately security trimmed. 
    Disabling allows for better performance but should only be applied to sites or page layouts that do not have
    information that needs security trimming.

.Parameter Enabled
    Turns caching on.

.Parameter Duration
    Duration in seconds to keep the cached version available. Defaults to 1 day (86400).

.Parameter CheckForChanges
    Check for Changes calidates on each page request that the site has not changed and flushes the cache on changes to the site. 
    Disabling can improve performance but will not check for updates to the site for the number of seconds specified 
    in duration.

.Parameter VaryByCustom
    Vary by Custom Parameter, As specified by HttpCachePolicy.SetVaryByCustom in ASP.Net 2.0.

.Parameter VaryByHeaders
    Vary by HTTP Header, As specified by HttpCachePolicy.VaryByHeaders in ASP.Net 2.0.

.Parameter VaryByParams
    Vary by Query String Parameters, As specified by HttpCachePolicy.VaryByParams in ASP.Net 2.0.

.Parameter VaryByUserRights
    Vary by User Rights ensures that users must have identical effective permissions on all securable objects to see 
    the same cached page as any other user.

.Parameter Cacheability
    As specified by HttpCacheability in ASP.Net 2.0.

.Parameter SafeAuthenticatedUse
    Safe for Authenticated Use is for only those policies that you want to allow to be applied to authenticated 
    scenarios by administrators and page layout designers.

.Parameter AllowWritersView
    Allow writers to view cached content bypasses the normal behavior of not allowing people with edit permissions 
    to have their pages cached. This should only be used in scenarios in which you know that the page will be 
    published, but will not have any content that might be checked out or in draft.

.Link Configure cache settings for a web application in SharePoint Server 2013
    https://technet.microsoft.com/en-us/library/cc770229.aspx

.Link Output Caching and Cache Profiles in SharePoint Server 2010 (ECM)
    https://msdn.microsoft.com/en-us/library/office/aa661294.aspx

.Notes
    Name:      Create-CustomCacheProfile
    Author:    Travis Smith
    LastEdit:  05/05/2014  

#>
Function Create-CustomCacheProfile()
{
    Param(
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
        [Microsoft.SharePoint.SPWeb]
        $Web,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Url,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Title,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $DisplayName,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Description,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $ACLCheck,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $Enabled,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
        $Duration = 86400,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $CheckForChanges,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $VaryByCustom,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $VaryByHeaders,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $VaryByParams,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $VaryByUserRights,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Cacheability,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $SafeAuthenticatedUse,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $AllowWritersView

    )
    BEGIN {
        $disposeSite = $false
        $disposeWeb = $false
        if (!$Url -and !$Site -and !$Web)
        {
            throw("Missing at least one parameter -Site or -Url or -Web")
        }


        if (!$Site)
        {
            if ($Url)
            {
                $Web = Get-SPSite $Url
            }
            elseif ($Web)
            {
                $Site = $Web.Site
            }
            else
            {
                throw("Unable to retrieve Site Collection (SPSite)")
            }

            $disposeSite = $true

        }

        if (!$Web)
        {
            if ($Url)
            {
                $Web = Get-SPWeb $Url
            }
            elseif ($Site)
            {
                $Web = Get-SPWeb $Site.Url
            }
            else
            {
                throw("Unable to retrieve Site (SPWeb)")
            }
            $disposeWeb = $true
        }

        if (!$Url)
        {
            if ($Site)
            {
                $Url = $Site.Url
            }
            elseif ($Site)
            {
                $Url = $Web.Url
                
            }
        }        
    }
    PROCESS {
        $list = $web.Lists["Cache Profiles"]
        $ctCacheProfile = $list.ContentTypes["Page Output Cache"]
        $profile = $list.Items.Add()
        $profile["ContentTypeId"] = $ctCacheProfile.Id
        $profile.Update()

        # Required. The system name of this cache profile.
        $profile["Title"] = "VS Cache Profile"

        # Populates the list of available cache profiles for site owners and page layout owners.
        $profile["Display Name"] = "VS Cache Profile"

        #Populates the list of available cache profiles for site owners and page layout owners.
        $profile["Display Description"] = "Custom Cache Profile for Acme"

        #Select to ensure that all items in the cache are security trimmed.
        $profile["Perform ACL Check"] = $true

        #Select if you want caching to happen.
        $profile["Enabled"] = $true

        #Number of seconds to keep the cached version available.
        $profile["Duration"] = "86400"

        #Select to validate on each page request that the site has not changed and to flush the 
        #cache when the site changes.
        #Clear if you want better performance. If unchecked, system does not check for updates 
        #to sites for the number of seconds specified in Duration.
        $profile["Check for Changes"] = $false

        #Specify a value as described in the ASP.NET HttpCachePolicy.SetVaryByCustom method documentation.
        #https://msdn.microsoft.com/en-us/library/system.web.httpcachepolicy.setvarybycustom(v=vs.110).aspx
        $profile["Vary by Custom Parameter"] = "Browser"

        #Specify a value as described in the ASP.NET HttpCachePolicy.VaryByHeaders property documentation.
        #https://msdn.microsoft.com/en-us/library/system.web.httpcachepolicy.varybyheaders(v=vs.110).aspx
        #HTTP headers that will be used to vary cache output.
        #If you want to vary the cached content by multiple headers, 
        #you need to set multiple values in the VaryByHeaders property. 
        #If you want to vary by all headers, set VaryByHeaders["Vary By Unspecified Parameters"] to true.
        $profile["Vary by HTTP Header"] = ""

        #Specify a value as described in the ASP.NET HttpCachePolicy.VaryByParams property documentation.
        #https://msdn.microsoft.com/en-us/library/system.web.httpcachepolicy.varybyparams(v=vs.110).aspx
        #parameters received by an HTTP GET or HTTP POST that affect caching.
        $profile["Vary by Query String Parameters"] = ""

        #Select to ensure that users must have identical effective rights on all SharePoint security scopes 
        #to see the same cached page as any other user.
        $profile["Vary by User Rights"] = $true

        #Choose a value from the drop-down list.
        #Choices include NoCache, Private, Server, ServerAndNoCache, Public, and ServerAndPrivate.
        #To learn more, see the ASP.NET HttpCacheability enumeration topic.
        #https://msdn.microsoft.com/en-us/library/system.web.httpcacheability(v=vs.110).aspx
        $profile["Cacheability"] = "ServerAndPrivate"

        #Select only for policies that you want to allow administrators and page layout designers to apply 
        #to authenticated scenarios.
        $profile["Safe for Authenticated Use"] = $true

        #Select to bypass the default behavior of not allowing people with edit rights to cached their pages.
        $profile["Allow writers to view cached content"] = $false

        #Update
        $profile.Update()

        #Add the profile to your Page Output Cache and enable the cache
        $cacheSettings = New-Object Microsoft.SharePoint.Publishing.SiteCacheSettingsWriter($Url)
        $cacheSettings.EnableCache = $true
        $cacheSettings.SetAuthenticatedPageCacheProfileId($site, $profile.ID)
        $cacheSettings.Update()
    }
    END {
        if ($disposeWeb)
        {
            $Web.Dispose()
        }
        if ($disposeSite)
        {
            $Site.Dispose()
        }
    }
}