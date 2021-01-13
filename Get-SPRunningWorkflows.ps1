
  

#Pages List Name
$list = $web.Lists["Pages"];


Function Get-SPRunningWorkflows {
	[CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Web")]
        [System.String]
        $URL,
		
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("List")]
        [System.String]
        $ListName
	)
	BEGIN {
		#Start, SP Site URL
		$web = Get-SPWeb $URL
		$web.AllowUnsafeUpdates = $true
		
		#List Name
		$list = $web.Lists[$ListName]
	}
	PROCESS {
		#Loop through all Items in List then loop through all Workflows on each List Items.         
		foreach ($listItem in $list.Items)  {
			 foreach ($workflow in $listItem.Workflows) {
				   #Disregard Completed or Cancelled Workflows 
				   if(($listItem.Workflows |
				   where-object {$_.InternalState -ne "Completed" -and $_.InternalState -ne "Cancelled"{}) -ne $null)
				   {
						#Print Items with Workflows in Progress
						#Place cancel command here to cancel ALL 
						write-output "Workflow :
								   " $workflow;
						write-output "in progress for : 
								   " $listItem.Title;  
				   }
			 }
		}
	}
	END {
		$web.Dispose();
	}
}