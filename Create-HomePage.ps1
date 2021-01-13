# http://intranet.example.com/sites/test
<#
.SYNOPSIS
    Creates a page based on a layout and sets as home page for Publishing Site and Team Site
    with Publishing Features enabled.

.DESCRIPTION
    Creates a page based on a layout and sets as home page for Publishing Site and Team Site
    with Publishing Features enabled.

.NOTES
    File Name: Create-HomePage.ps1
    Author   : Travis Smith
    Version  : 1.0

.PARAMETER Url
    Specifies the URL of the Site (SP-Web) to create the home page. 
	 
.PARAMETER Layout
    Specifies the layout of the home page to be created.

.PARAMETER LayoutContentType
    Specifies the layout content type of the home page to be created.

.EXAMPLE
    PS > .\Create-HomePage.ps1 -Url http://intranet.example.com
    PS > .\Create-HomePage.ps1 -Url http://intranet.example.com

#>
param( 
    [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)] 
    [string]
    $Url,

    [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        Position=1,
        HelpMessage="If -Layout is set, then -LayoutContentType must be set.")] 
    [string]$Layout,

    [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        Position=2,
        HelpMessage="If -LayoutContentType is set, then -Layout must be set.")] 
    [string]
    $LayoutContentType
) 

# Add the SharePoint PowerShell snap-in
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

if ($Layout -ne $null && $LayoutContentType -e $null)
{
    System.ArgumentNullException
}
$Url = "http://intranet.example.com/sites/test"

# Get publishing web
$SPWeb = Get-SPWeb $Url
$pweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($SPWeb)

$SPSite = Get-SPSite $Url
$pweb = [Microsoft.SharePoint.Publishing.PublishingSite]::GetPublishingSite($SPSite)

# List of pages
$pages = $pweb.GetPublishingPages($pweb)
$pages["home.aspx"]

# Get a page layout
$Url = "http://intranet.example.com/sites/test"
$psite = Get-SPSite -Limit All | Where { $_.Url -eq (Get-SPWeb $Url).Url }
#$SPWeb.Lists | Sort-Object -Property Title | Format-Table -Property Title
foreach ($lst in $SPWeb.lists)
{
    $SPWeb.Items | Sort-Object -Property Title | Format-Table -Property Title
    #foreach ($item in $lst.Items)
    #{
    #    if ($item.ContentType.Name -eq "Document")
    #    { $item.Url}
    #}
}
<#
$ctype = $psite.ContentTypes["Publishing Page"]
$pageLayouts = $psite.GetPageLayouts($ctype, $true)
$pageLayouts | ForEach-Object {
  if ($_.Title -eq "Your Page Layout Title")
  {
    $layout = $_;
  }
}*/
#>

# Find existing home page
$pages | ForEach-Object {
    if($_.Name -eq "home.aspx")
    {
        $page = $_;
    }
}

if ($page -ne $null)
{
    # Create page based on layout
    $page = $pages.Add("home.aspx", $pweb.DefaultPageLayout)
    $page.Title = "Home";
    
    # Update Layout
    <#
    if ($page -ne $null)
    {
        $page.CheckOut()
        $page.Layout  = $layout; 
        $page.Update();
    }
    #>

    $page.Update();
    
    # Update other fields
    <#$item = $page.ListItem
    if ($pg.PageContent -ne "")
    {
        $item["Title"] = "Your Title";
        $item["Page Content"] = "Your content";
        $item.Update() 
    }#>

    # Check-in & publish
    $page.CheckIn("")
    $page.Publish("")
    $page.Approve("")
}

# Set page as home page
$pweb.DefaultPage = $page
$pweb.Update()

$SPWeb.Dispose()