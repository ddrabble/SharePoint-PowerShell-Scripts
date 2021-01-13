param 
(
    [string]$WebApplicationUrl = "",
	[string]$PageLayoutName = ""
)

Remove-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue
Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue

Function DeletePageLayout([string]$WebAppUrl, [string]$PageLayout)
{
	$WebApp = Get-SPWebApplication $WebAppUrl
	Write-Host -ForegroundColor White "Starting to remove page layout"
	foreach ($SPSite in $webApp.Sites)
	{
		[Microsoft.Sharepoint.Publishing.PublishingSite]$PublishingSite = New-Object Microsoft.SharePoint.Publishing.PublishingSite($SPSite)
		if ([Microsoft.SharePoint.Publishing.PublishingWeb]::IsPublishingWeb($PublishingSite.RootWeb) -eq $true)
		{
			$SiteName = $PublishingSite.RootWeb
			Write-Host -ForegroundColor Green "Searching site: $SiteName"
			$PageLayouts = $PublishingSite.GetPageLayouts($false)

			foreach($Layout in $PageLayouts)
			{
			   [Microsoft.SharePoint.SPFile]$File = $PublishingSite.RootWeb.GetFile($Layout.ServerRelativeUrl);
			   $FileName = $File.Name

				if ($FileName -eq $PageLayout)
				{
					Write-Host -ForegroundColor White "File: $FileName"
					$IsPageLayoutInUse = ($File -ne $null -and $File.BackwardLinks -ne $null -and $File.BackwardLinks.Count -gt 0)
					if ($IsPageLayoutInUse -eq $false)
					{
						Write-Host -ForegroundColor White "Deleting: $PageLayout"
						Write Host $File.Delete()
						Write-Host -ForegroundColor White "Successfully deleted: $PageLayout"
					}
                    else
                    {
                        $Count = $File.BackwardLinks.Count;
                        Write-Host -ForegroundColor Red "File, $PageLayout, is in use ($Count)."
                        Write-Host ""
                    }
				}
			}
		}
	}  
}		

If (!([string]::IsNullOrEmpty($WebApplicationUrl)))
{
	If (!([string]::IsNullOrEmpty($PageLayoutName)))
	{
		DeletePageLayout $WebApplicationUrl $PageLayoutName
	}
	Else
	{
		Throw " - Please provide the page layout parameter -PageLayoutName"
	}
}
Else
{
    Throw " - Please provide the web application url parameter -WebApplicationUrl"
}