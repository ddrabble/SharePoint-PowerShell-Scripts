param (
    $SiteUrl = "http://intranet.example.com/dev"
)

# Add the SharePoint PowerShell snap-in
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

function Import-PublishingPage {
    param (
        $SiteUrl = $(throw "Required parameter -SiteUrl missing"),
        [xml]$PageXml = $(throw "Required parameter -PageXml missing")
    )
 
    $site = New-Object Microsoft.SharePoint.SPSite($SiteUrl)
    $psite = New-Object Microsoft.SharePoint.Publishing.PublishingSite($site)
    $web = Get-SPWeb $SiteUrl
    $pweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web)
    $pagesListName = $pweb.PagesListName
 
    # get prerequisites
    $pageName = $PageXml.Module.File.Url
    if (-not($pageName)) {
        throw "Page name missing in <File Url='...'/>"
    }
 
    $plDefinition = $PageXml.Module.File.Property | Where { $_.Name -eq "PublishingPageLayout" }
    if (-not($plDefinition)) {
        throw "Page Layout reference missing in <File><Property Name='PublishingPageLayout' Value='...'/></File>"
    }
 
    $plUrl = New-Object Microsoft.SharePoint.SPFieldUrlValue($plDefinition.Value)
    $plName = $plUrl.Url.Substring($plUrl.Url.LastIndexOf('/') + 1)
    $pl = $psite.GetPageLayouts($false) | Where { $_.Name -eq $plName }
    Write-Host $plUrl
    Write-Host $plName
    Write-Host $plDefinition

    if (-not($pl)) {
        throw "Page Layout '$plName' not found"
    }
 
    [Microsoft.SharePoint.Publishing.PublishingPage]$page = $null
    $file = $web.GetFile("$pagesListName/$pageName")
    if (-not($file.Exists)) {
        Write-Host "Page $pageName not found. Creating..." -NoNewline
        $page = $pweb.AddPublishingPage($pageName, $pl)
        Write-Host "DONE" -ForegroundColor Green
    }
    else {
        Write-Host "Configuring '$($file.ServerRelativeUrl)'..."
        $item = $file.Item
        $page = [Microsoft.SharePoint.Publishing.PublishingPage]::GetPublishingPage($item)
        if ($page.ListItem.File.CheckOutStatus -eq [Microsoft.SharePoint.SPFile+SPCheckOutStatus]::None) {
            $page.CheckOut()
        }
    }
 
    if ($PageXml.Module.File.AllUsersWebPart) {
        Write-Host "`tImporting Web Parts..." -NoNewline
 
        # fake context
        [System.Web.HttpRequest] $request = New-Object System.Web.HttpRequest("", $web.Url, "")
        $sw = New-Object System.IO.StringWriter
        $hr = New-Object System.Web.HttpResponse($sw)
        [System.Web.HttpContext]::Current = New-Object System.Web.HttpContext($request, $hr)
        [Microsoft.SharePoint.WebControls.SPControl]::SetContextWeb([System.Web.HttpContext]::Current, $web)
 
        $wpMgr = $web.GetLimitedWebPartManager("$pagesListName/$pageName", [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
        foreach ($webPartDefinition in $PageXml.Module.File.AllUsersWebPart) {
            $err = $null
            $sr = New-Object System.IO.StringReader($webPartDefinition.InnerText)
            $xtr = New-Object System.Xml.XmlTextReader($sr);
            $wp = $wpMgr.ImportWebPart($xtr, [ref] $err)
            $oldWebPartId = $webPartDefinition.ID.Trim("{", "}")
            $wp.ID = "g_" + $oldWebPartId.Replace("-", "_")
            $wpMgr.AddWebPart($wp, $webPartDefinition.WebPartZoneID, $webPartDefinition.WebPartOrder)
            Write-Host "." -NoNewline
        }
 
        [System.Web.HttpContext]::Current = $null
        Write-Host "`n`tWeb Parts successfully imported"
    }
    else {
        Write-Host "`tNo Web Parts found"
    }
 
    Write-Host "`tImporting content..."
    $li = $page.ListItem
    foreach ($property in $PageXml.Module.File.Property) {
        Write-Host "`t$($property.Name)..." -NoNewline
        $field = $li.Fields.GetField($property.Name)
        if (-not($field.IsReadOnlyField)) {
            try {
                $value = $field.GetValidatedString($property.Value.Replace("~SiteCollection/", $site.ServerRelativeUrl).Replace("~Site/", $web.ServerRelativeUrl))
                if ($value) {
                    $li[$property.Name] = $value
                    Write-Host "DONE" -ForegroundColor Green
                }
                else {
                    Write-Host "SKIPPED (Invalid value)" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "SKIPPED (Invalid value)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "SKIPPED (ReadOnly)" -ForegroundColor Red
        }
    }
    $li.Update()
    Write-Host "`tContent import completed" -ForegroundColor Green
 
    $page.CheckIn("")
    $file = $page.ListItem.File
    $file.Publish("")
    #$file.Approve("")
 
    Write-Host "Page successfully imported" -ForegroundColor Green
}
 
$pages = @{
    "home_default.aspx.xml" = "/"

}
 
$pages.GetEnumerator() | % {
    Write-Host "$($_.Name)"
    [xml]$pageXml = Get-Content "$($_.Name)"
    Import-PublishingPage "$SiteUrl$($_.Value)" $pageXml
}