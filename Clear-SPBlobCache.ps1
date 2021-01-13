Function Clear-SPBlobCache {
	Param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("WebApplicationURL")]
        [System.String]
		$URL
	)
	BEGIN {
		#Loading SharePoint Powershell Snaping
		Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue
	}
	PROCESS {
		Write-Host "Checking:" $URL
		$webApp = Get-SPWebApplication $URL
		[Microsoft.SharePoint.Publishing.PublishingCache]::FlushBlobCache($webApp)
		Write-Host "Flushed the BLOB cache for:" $webApp
	}
}