Function Start-SPServices {
	[CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SPServices")]
        [System.Collections.ArrayList]
        $Services = @("SPAdminV4", "SPTimerV4", "SPTraceV4", "SPUserCodV4", "SPWriterV4", "W3SVC", "OSearch15")
	)
	PROCESS {
		foreach ($service in $Services)
		{
			Write-Host -foregroundcolor green "Starting $service …"
			Start-Service -Name $service
		}
	}
	END {
		iisreset /start
	}
}

Function Stop-SPServices {
	[CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SPServices")]
        [System.Collections.ArrayList]
        $Services = @("SPAdminV4", "SPTimerV4", "SPTraceV4", "SPUserCodV4", "SPWriterV4", "W3SVC", "OSearch15")
	)
	PROCESS {
		foreach ($service in $Services)
		{
			Write-Host -foregroundcolor green "Starting $service …"
			Stop-Service -Name $service
		}
	}
	END {
		iisreset /start
	}
}