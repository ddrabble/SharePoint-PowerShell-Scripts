function Check-ADUserPermission(
    [System.DirectoryServices.DirectoryEntry]$entry, 
    [string]$user, 
    [string]$permission)
{
    $dse = [ADSI]"LDAP://Rootdse"
    $ext = [ADSI]("LDAP://CN=Extended-Rights," + $dse.ConfigurationNamingContext)

    $ext.psbase.Children

    $right = $ext.psbase.Children | 
        ? { $_.DisplayName -eq $permission }

    if($right -ne $null)
    {
        $perms = $entry.psbase.ObjectSecurity.Access |
            ? { $_.IdentityReference -eq $user } |
            ? { $_.ObjectType -eq [GUID]$right.RightsGuid.Value }

        return ($perms -ne $null)
    }
    else
    {
        Write-Warning "Permission '$permission' not found."
        return $false
    }
}