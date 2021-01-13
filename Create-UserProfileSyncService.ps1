Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

function Get-SPServiceContext(
    [Microsoft.SharePoint.Administration.SPServiceApplication]$profileApp)
{
    if($profileApp -eq $null)
    {
        # Get first User Profile Service Application
        $profileApp = @(Get-SPServiceApplication | 
            ? { $_.TypeName -eq "User Profile Service Application" })[0]
    }
    
    return [Microsoft.SharePoint.SPServiceContext]::GetContext(
        $profileApp.ServiceApplicationProxyGroup, 
        [Microsoft.SharePoint.SPSiteSubscriptionIdentifier]::Default)
}

function Convert-ToList($inputObject, [System.String]$Type)
{
    begin
    {
        if($type -eq $null -or $type -eq '') 
        {
            $type = [string]
        }
    
        $list = New-Object System.Collections.Generic.List[$type]
    }
    
    process { $list.Add($_) }
    
    end
    {
        return ,$list
    }
}

function Get-DC($domainName)
{
    return ("DC=" + $domainName.Replace(".", ",DC="))
}

# Types

$DirectoryServiceNamingContextType = [Microsoft.Office.Server.UserProfiles.DirectoryServiceNamingContext, Microsoft.Office.Server.UserProfiles, Version=14.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c]

# Globals

$connectionName = "sparks.local"
$domainName = "acme.local"
$accountName = "ACME\spsvc_farm"
$password = ConvertTo-SecureString "zBQ!4AzRKH3Jhan" -AsPlainText -Force

$partitions = @{
     "acme.local" = @("DC=acme,DC=local");
     };

# Main()

# Prepare Parameters

$userDomain = $accountName.Substring(0, $accountName.IndexOf("\"))
$userName = $accountName.Substring($accountName.IndexOf("\") + 1)

$dnContexts = $partitions.GetEnumerator() |
     % {
     $domainName = $_.Key
     $containers = $_.Value | Convert-ToList
    
     $partition = [ADSI]("LDAP://" + (Get-DC $domainName))

     $partitionId = New-Object Guid($partition.objectGUID)

     New-Object $DirectoryServiceNamingContextType(
        $partition.distinguishedName, 
        $domainName, 
        <# isDomain: #> $false, 
        <# objectId: #> $partitionId, 
        <# containersIncluded: #> $containers, 
        <# containersExcluded: #> $null, 
        <# preferredDomainControllers: #> $null, 
        <# useOnlyPreferredDomainControllers: #> $false)
    } | Convert-ToList -Type $DirectoryServiceNamingContextType

$partition = [ADSI]("LDAP://CN=Configuration," + (Get-DC $domainName))
$partitionId = New-Object Guid($partition.objectGUID)

$containers = @($partition.distinguishedName) | Convert-ToList

$dnContext = New-Object $DirectoryServiceNamingContextType(
    $partition.distinguishedName, 
    $domainName, 
    <# isDomain: #> $true, 
    <# objectId: #> $partitionId, 
    <# containersIncluded: #> $containers, 
    <# containersExcluded: #> $null, 
    <# preferredDomainControllers: #> $null, 
    <# useOnlyPreferredDomainControllers: #> $false)

$dnContexts.Add($dnContext)


# Create Active Directory Connection

$serviceContext = Get-SPServiceContext

$configManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($serviceContext)

if($configManager.ConnectionManager.Contains($connectionName) -eq $false)
{
    $configManager.ConnectionManager.AddActiveDirectoryConnection(
        [Microsoft.Office.Server.UserProfiles.ConnectionType]::ActiveDirectory, 
        $connectionName, $domainName, <# useSSL: #> $false, 
        $userDomain, $userName, $password, 
        <# namingContexts #> $dnContexts, 
        <# spsClaimProviderTypeValue: #> $null, 
        <# spsClaimProviderIdValue: #> $null)
}
else
{
    Write-Host "Connection '$connectionName' already exist. Delete it before run this script."
}