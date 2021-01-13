Add-PSSnapin Microsoft.SharePoint.PowerShell -ea 0; 
Function Disable-SPLoopback
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Urls")]
        [System.Collections.ArrayList]
        $Data,
        # "mytest.sharepoint.com`r`ntest.sharepoint.com`r`nmyloadbalancer.sharepoint.com"

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $AddDisableStrictNameChecking,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $Force,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $Confirm
    )
	BEGIN {
		if (!$AddDisableStrictNameChecking.IsPresent) {
			$AddDisableStrictNameChecking = $true;
		}
	}
    PROCESS {
        
        # Maybe Add AddDisableStrictNameChecking
        if ($AddDisableStrictNameChecking)
        {
			Write-Verbose "Adding DisableStrictNameChecking..."
			
            # Add DisableStrictNameChecking
            New-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters" `
                -Name "DisableStrictNameChecking" -Value 1 -PropertyType "DWord" -Force:$Force -Verbose:$Verbose
        }

        # Add BackConnectionHostNames in HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0
        Add-SPMultiStringKey -Data $Data -Force:$Force -Verbose:$Verbose

        # See if DisableLoopbackCheck key exists in HKLM:\System\CurrentControlSet\Control\Lsa and remove if so
        if ((Check-SPDisableLoopbackCheck))
        {
            $DisableLoopback = Get-SPRegistryValueData -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Value "DisableLoopbackCheck"
            Write-Verbose "DisableLoopbackCheck Value:  ${$DisableLoopback}"
            Write-Verbose "Removing DisableLoopbackCheck..."

            # Remove DisableLoopbackCheck
            Get-Item -path "HKLM:\System\CurrentControlSet\Control\Lsa" -Verbose:$Verbose |
                Remove-ItemProperty -name "DisableLoopbackCheck" -Confirm:$Confirm -Verbose:$Verbose
        }
        
    }
}

Function Check-SPDisableLoopbackCheck
{
    [CmdletBinding()]
    param()
    PROCESS {
        Write-Verbose "Checking if DisableLoopbackCheck exists?"
        if ((Test-SPRegistryValue -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Value "DisableLoopbackCheck"))
        #if ((Get-SPRegistryValueData -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Value "DisableLoopbackCheck"))
        {
            Write-Verbose "DisableLoopbackCheck in HKLM:\System\CurrentControlSet\Control\Lsa exists. Checking value..."
            if ((Get-SPRegistryValueData -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Value "DisableLoopbackCheck") -eq 1)
            {
                Write-Verbose "Loopback is disabled with Method #2 using DisableLoopbackCheck in HKLM:\System\CurrentControlSet\Control\Lsa, the less preferred method."
                Return $true
            }
            else
            {
                Write-Verbose "DisableLoopbackCheck in HKLM:\System\CurrentControlSet\Control\Lsa: $(Get-SPRegistryValueData -Path "HKLM:\System\CurrentControlSet\Control\Lsa" -Value "DisableLoopbackCheck")"
                Return $false
            }
        }
        else
        {
            Write-Verbose "DisableLoopbackCheck does not exist."
            Return $false
        }
    }
}

Function Add-SPMultiStringKey
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Collections.ArrayList]
        $Data,
        # "mytest.sharepoint.com`r`ntest.sharepoint.com`r`nmyloadbalancer.sharepoint.com"

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Path")]
        [System.String]
        $Key = "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
        $Name = "BackConnectionHostNames",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Switch]
        $Force
    )
    BEGIN {
        # Check to see if Key exists
        $keyExists = Test-SPRegistryValue -Path $Key -Value $Name -Verbose:$Verbose
        if (!$Force -and $keyExists)
        {
            # Key already exists
            Write-Host "BackConnectionHostNames Key already exists." -ForegroundColor Red
            [System.String]$f = Read-Host "Shall we over-write? [Y] Yes [N] No"
            if ($f -eq "Y" -or $f -eq "y")
            {
                $Force = $true
            }
            else
            {
                Write-Verbose "BackConnectionHostNames Key already exists."
            }
        }
    }
    PROCESS {
        try {
            if (!$Force -and $keyExists)
            {
                Write-Verbose "Exiting..."
                Return
            }
            New-ItemProperty $Key -Name $Name `
                -value $Data -PropertyType MultiString -Force:$Force -Verbose:$Verbose -ErrorAction SilentlyContinue
                #-value ($Data -join '`r`') -PropertyType MultiString -Force:$Force -Verbose:$Verbose -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "BackConnectionHostNames Key already exists! No changes made." -ForegroundColor Red
            Return
        }
    }
    END {
        if ((Test-SPRegistryValue -Path $Key -Value $Name -Verbose:$Verbose))
        {
            Write-Verbose "$Name in $Key has a value of '$(Get-SPRegistryValueData -Path $Key -Value $Name -Verbose:$Verbose)'."
        }
        else
        {
            Write-Verbose "Opps. Something happened?? $Name in $Key has a value of '$(Get-SPRegistryValueData -Path $Key -Value $Name -Verbose:$Verbose)'."
        }
    }
}

Function Test-SPRegistryValue
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        $Value
    )
    try {
        Get-ItemProperty -Path $Path -Verbose:$Verbose | Select-Object -ExpandProperty $Value -ErrorAction Stop -Verbose:$Verbose | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

Function Get-SPRegistryValueData
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        $Value
    )
    #Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value
    try {
        $value = Get-ItemProperty -Path $Path -Verbose:$Verbose | Select-Object -ExpandProperty $Value -ErrorAction Stop -Verbose:$Verbose
        return $value
    }

    catch {
        return $null
    }
}

Function Add-SPMultiStringKeyData
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Path")]
        [System.String]
        $Key = "HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0",

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        $Value = "BackConnectionHostNames",

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Data
    )
    PROCESS {
        $currentValueData = @()
        $currentValueData = (Get-SPRegistryValueData -Path $Key -Value $Value) -split '`r`'
        $currentValueData += $Data
        Add-SPMultiStringKey $currentValueData -Force
    }
}

Function Add-SPRegistryKeyPermission
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Key")]
        [System.String]
        $regKey,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Account")]
        [System.String]
        $regAccount = "$env:COMPUTERNAME\WSS_WPG",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Permission")]
        [System.String]
        $regPermission = "FullControl",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("PermissionToggle")]
        [System.String]
        $regPermToggle = "Allow"
    )
    PROCESS {
        $acl = Get-Acl $regKey -Verbose:$Verbose
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($regAccount,$regPermission,"ContainerInherit","None",$regPermToggle) -Verbose:$Verbose
        $acl.SetAccessRule($rule)
        $acl | Set-Acl -Path $regKey -Verbose:$Verbose
    }
}

Function Add-SPRegistryKeysPermission
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Keys")]
        [System.Collections.ArrayList]
        $regKeys = @("HKLM:\SYSTEM\CurrentControlSet\Services\BITS\Performance","HKLM:\SYSTEM\CurrentControlSet\Services\WmiApRpl\Performance"),

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Account")]
        [System.String]
        $regAccount = "$env:COMPUTERNAME\WSS_WPG",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Permission")]
        [System.String]
        $regPermission = "FullControl",

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("PermissionToggle")]
        [System.String]
        $regPermToggle = "Allow"
    )
    PROCESS {
        foreach ($regKey in $regKeys){
            Add-SPRegistryKeyPermission -Key $regKey -Account $regAccount -Permission $regPermission -PermissionToggle $regPermToggle -Verbose:$Verbose
        }
    }
}