<# 
.Synopsis
    Exports the Managed Metadata Information.
    
.Description
    Exports the Managed Metadata Information to a CAB file.
    
.Parameter Path
    The path to the place the exported *.cab file, including the filename. Default: "C:\ExportedMetadata.cab"

.Parameter Name ("Application")
	Name of the Managed Metadata Service. Default: "Managed Metadata Service".

.Parameter Proxy ("ApplicationProxy")
	Name of the Managed Metadata Service Proxy. Default: "Managed Metadata Service Connection".

.Example
	Export-ManagedMetaData

.Notes
    Name:      Export-ManagedMetaData
    Author:    Travis Smith
    LastEdit:  07/14/2015

#>
Function Export-ManagedMetaData {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$Path = "C:\ExportedMetadata.cab",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Application")]
        [System.String]
		$Name = "Managed Metadata Service",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("ApplicationProxy")]
        [System.String]
		$Proxy = "Managed Metadata Service Connection",
	)
	BEGIN {
		$mmsApplication = Get-SPServiceApplication | ? {$_.TypeName -eq $Name}
		$mmsProxy = Get-SPServiceApplicationProxy | ? {$_.TypeName -eq $Proxy}
	}
	PROCESS {
		Export-SPMetadataWebServicePartitionData $mmsApplication.Id -ServiceProxy $mmsProxy -Path $Path
	}
}

<# 
.Synopsis
    Imports the Managed Metadata Information.
    
.Description
    Imports the Managed Metadata Information to a CAB file.
    
.Parameter Path
    The path to the place the exported *.cab file, including the filename. Default: "C:\ExportedMetadata.cab"

.Parameter Name ("Application")
	Name of the Managed Metadata Service. Default: "Managed Metadata Service".

.Parameter Proxy ("ApplicationProxy")
	Name of the Managed Metadata Service Proxy. Default: "Managed Metadata Service Connection".

.Example
	Import-ManagedMetaData

.Notes
    Name:      Import-ManagedMetaData
    Author:    Travis Smith
    LastEdit:  07/14/2015

#>
Function Import-ManagedMetaData {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$Path = "C:\ExportedMetadata.cab",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Application")]
        [System.String]
		$Name = "Managed Metadata Service",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("ApplicationProxy")]
        [System.String]
		$Proxy = "Managed Metadata Service Connection",
	)
	BEGIN {
		$mmsApplication = Get-SPServiceApplication | ? {$_.TypeName -eq $Name}
		$mmsProxy = Get-SPServiceApplicationProxy | ? {$_.TypeName -eq $Proxy}
	}
	PROCESS {
		Import-SPMetadataWebServicePartitionData $mmsApplication.Id -ServiceProxy $mmsProxy -Path $Path -OverwriteExisting
	}
}
