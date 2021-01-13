function Get-WebTemplate
{
    Param(
      [Parameter(ValueFromPipeline=$true,ParameterSetName="Path",Mandatory)]
      [String]$url = "http://intranet.example.com"
    )

    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
    $web = Get-SPWeb $url
    #$web.WebTemplate + " " + $web.WebTemplateId
    Write-host “Web Template:” $web.WebTemplate ” | Web Template ID:” $web.WebTemplateId 
    $web.close()
}

Get-WebTemplate -url "http://intranet.example.com/department/sales"
