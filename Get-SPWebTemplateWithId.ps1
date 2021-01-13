function Get-SPWebTemplateWithId 
{ 
     $templates = Get-SPWebTemplate | Sort-Object "Name" 
     $templates | ForEach-Object { 
    $templateValues = @{ 
     "Title" = $_.Title 
     "Name" = $_.Name 
     "ID" = $_.ID 
     "Custom" = $_.Custom 
     "LocaleId" = $_.LocaleId 
      }

New-Object PSObject -Property $templateValues | Select @("Name","Title","LocaleId","Custom","ID") 
      } 
}