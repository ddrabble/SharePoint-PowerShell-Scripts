<# 
.Synopsis
    Runs the Health Analyzer.
    
.Description
    Runs the Health Analyzer.
    
.Parameter Name
	Name of the Health Analysis Job. Default: "Health Analysis Job*".

.Example
	Run-HealthAnalysis

.Notes
    Name:      Run-HealthAnalysis
    Author:    Travis Smith
    LastEdit:  07/14/2015

#>
Function Run-HealthAnalysis {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$Name = "Health Analysis Job*"
	)
	$jobs = Get-SPTimerJob | Where-Object {$_.Title -like $Name}
	foreach ($job in $jobs)
	{
	  $job.RunNow()
	}
}