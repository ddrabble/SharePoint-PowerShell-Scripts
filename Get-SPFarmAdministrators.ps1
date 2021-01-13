Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue
function Get-SPfarmAdministrators {
  $adminwebapp = Get-SPwebapplication -includecentraladministration | where {$_.IsAdministrationWebApplication}
  $adminsite = Get-SPweb($adminwebapp.Url)
  $AdminGroupName = $adminsite.AssociatedOwnerGroup
  $farmAdministratorsGroup = $adminsite.SiteGroups[$AdminGroupName]
  return $farmAdministratorsGroup.users
}

function Add-SPfarmAdministrator { Param ([string] $LoginName) 
  $adminwebapp = Get-SPwebapplication -includecentraladministration | where {$_.IsAdministrationWebApplication}
  $adminsite = Get-SPweb($adminwebapp.Url)
  $admingroup = $adminsite.AssociatedOwnerGroup
  $adminsite.SiteGroups[$admingroup].AddUser($LoginName,"","","")
}
$farmadmins = Get-SPfarmAdministrators
$farmadmins | FT