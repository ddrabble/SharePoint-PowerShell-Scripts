<# 
.Synopsis
    Automated backup of the SharePoint Farm.
    
.Description
    Automates the backup of the SharePoint Farm backing up the Farm, Farm Config, Service Applications, and individual Site Collections.
    
.Parameter Path ("RootPath")
    The path to the root backups directory (e.g. \\servername\path\to\backups).

.Parameter Days
	Global. Number of days to maintain all backups. Over-ridden by ConfigDays, FarmDays, SitesDays, & SADays for their respective backups if they exist. Default: 7.

.Parameter From ("Sender")
	Global. Sender email address for all email notifications.

.Parameter To ("Alias")
	Global. Recipient(s) email address(es) for all email notifications.

.Parameter SMTPHost ("SMTP")
	Global. SMTP hostname or IP address.

.Parameter SubjectPrefix ("Subject")
	Global. Subject prefix of the email subject. Default: "[SP2013 Backup] "

.Parameter SPConfigFolderName ("SPConfigFolder")
	Folder name of the SP Config backups to be appended to the Root Path. Default: "Config".

.Parameter ConfigDays
	Placeholder. This is currently not in use. Number of days to maintain Config backups. Default (from Days): 7.

.Parameter FarmFolderName ("FarmFolder")
	Folder name of the Farm backups to be appended to the Root Path. Default: "Farm".

.Parameter FarmDays
	Number of days to maintain Farm backups. Default (from Days): 7.

.Parameter SPSitesFolderName ("SPSitesFolder")
	Folder name of the Site Collection backups to be appended to the Root Path. Default: "Sites".

.Parameter SitesDays
	Number of days to maintain Site Collection backups. Default (from Days): 7.

.Parameter SAFolderName ("SAFolder")
	Folder name of the Service Application backups to be appended to the Root Path. Default: "ServiceApplications".

.Parameter SADays
	Placeholder. This is currently not in use. Number of days to maintain Service Application backups. Default (from Days): 7.

.Example
	Backup-SP2013 -Path "\\example.local\common\APPDEV\Sharepoint\backups"
	              -Days 30
				  -From "no-reply@example.com"
				  -To "email@example.com"
				  -SMTP "relay.example.local"

.Notes
    Name:      Backup-SP2013
    Author:    Travis Smith
	Author:    Tim Hansen
    LastEdit:  07/14/2015

#>
Function Backup-SP2013 {
	[CmdletBinding()]
	param(
		## GLOBAL PARAMETERS ##
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("RootPath")]
        [System.String]
		$Path,
		
		# Over-ridden by FarmDays & SitesDays if they exist
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7,
		
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Sender")]
        [System.Collections.ArrayList]
		$From,
		
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Recipients")]
        [System.String]
		$To,
		
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("SMTP")]
        [System.String]
		$SMTPHost,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Subject")]
        [System.String]
		$SubjectPrefix = "[SP2013 Backup] ",
		
		## SPECIFIC PARAMETERS ##
		
		# Folder Names
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SPConfigFolder")]
        [System.String]
		$SPConfigFolderName = "Config",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$ConfigDays,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("FarmFolder")]
        [System.String]
		$FarmFolderName = "Farm",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$FarmDays,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SPSitesFolder")]
        [System.String]
		$SPSitesFolderName = "Sites",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$SitesDays,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SAFolder")]
        [System.String]
		$SAFolderName = "ServiceApplications",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$SADays
	)
	BEGIN {
		if ( (Get-PSSnapin -Name Microsoft.SharePoint.Powershell -EA "SilentlyContinue") -eq $null )
		{
			Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction "SilentlyContinue"
		}
		Write-SP2013Verbose "Root" "Starting" "Beginning backups..."
		
		# Create the Root Path
		Create-SP2013BackupDirectory $Path
		
		# Set the Sites/Farm Days Retention
		if (!$ConfigDays) {
			$ConfigDays = $Days
		}
		Write-SP2013Verbose "Root" "Starting" "Setting the Farm Backups Retention to $ConfigDays Days"
		
		if (!$FarmDays) {
			$FarmDays = $Days
		}
		Write-SP2013Verbose "Root" "Starting" "Setting the Farm Backups Retention to $FarmDays Days"
		
		if (!$SitesDays) {
			$SitesDays = $Days
		}
		Write-SP2013Verbose "Root" "Starting" "Setting the Site Collection Backups Retention to $FarmDays Days"
		
		if (!$SADays) {
			$SADays = $Days
		}
		Write-SP2013Verbose "Root" "Starting" "Setting the Service Application Backups Retention to $FarmDays Days"
		
		# Set Path Global Variables
		Set-Variable -Name "SP2013Path" -Value $Path -Scope Global
		
		# Set Email Global Variables
		Set-Variable -Name "SP2013From" -Value $From -Scope Global
		Set-Variable -Name "SP2013To" -Value $To -Scope Global
		Set-Variable -Name "SP2013SMTPHost" -Value $SMTPHost -Scope Global
		Set-Variable -Name "SP2013SubjectPrefix" -Value $SubjectPrefix -Scope Global
	}
	PROCESS {
		# Process Config Backup
		Backup-SP2013Config -Path $Path -Name $SPConfigFolderName -Days $ConfigDays -Verbose:$Verbose
		
		# Process Sites Backup
		Backup-SP2013Sites -Path $Path -Name $SPSitesFolderName -Days $SitesDays -Verbose:$Verbose
		
		# Process Farm Backup
		Backup-SP2013Farm -Path $FarmFolderName -Name $SPSitesFolderName -Days $FarmDays -Verbose:$Verbose
		
		# Process Service Applications Backup
		Backup-SP2013ServiceApplications -Path $FarmFolderName -Name $SAFolderName -Days $SADays -Verbose:$Verbose
	}
	END {
		Write-SP2013Verbose "Root" "Ending" "Backups Complete"
	}
}

<# 
.Synopsis
    Automated backup of the SharePoint Farm Config.
    
.Description
    Automates the backup of the SharePoint Farm Config.
    
.Parameter Path ("RootPath")
    The path to the root backups directory (e.g. \\servername\path\to\backups).

.Parameter Name ("DirectoryName")
	Folder name of the SP Config backups to be appended to the Root Path. Default: "Config".

.Parameter Days
	Number of days to maintain all backups. Default: 7.

.Example
	Backup-SP2013Config -Path "\\servername\path\to\backups\"

.Notes
    Name:      Backup-SP2013
    Author:    Travis Smith
	Author:    Tim Hansen
    LastEdit:  07/14/2015

#>
Function Backup-SP2013Config {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("DirectoryName")]
        [System.String]
		$Name = "Config",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7
	)
	BEGIN {
		Write-SP2013Verbose "Config" "Starting" "Beginning SP Config Backup"
		
		# Create SP Config Backup Directory
		if ($Name)
		{
			$ConfigPath = "$Path\$Name"
		}
		else
		{
			$ConfigPath = $Path
		}
		Create-SP2013BackupDirectory $ConfigPath
		$BackupPath = Get-SP2013Directory $FarmPath
		
		Write-SP2013Verbose "Config" "Starting" "Backing up SP2013 Farm to $ConfigPath"
	}
	PROCESS {
		Write-SP2013Verbose "Config" "Processing" "Backing up SP2013 Farm to $ConfigPath"
		
		# Run a new full configuration-only backup
		Backup-SPFarm -Directory $BackupPath -BackupMethod Full -ConfigurationOnly -Verbose:$Verbose -Percentage 15
	}
	END {
		Write-SP2013Verbose "Config" "Ending" "SP Config Backup Complete" -ForegroundColor "Green"
	}
}

<# 
.Synopsis
    Automated backup of the SharePoint Farm.
    
.Description
    Automates the backup of the SharePoint Farm.
    
.Parameter Path ("RootPath")
    The path to the root backups directory (e.g. \\servername\path\to\backups).

.Parameter Name ("DirectoryName")
	Folder name of the SP Config backups to be appended to the Root Path. Default: "Farm".

.Parameter Days
	Number of days to maintain all backups. Default: 7.

.Example
	Backup-SP2013Farm -Path "\\servername\path\to\backups\"

.Notes
    Name:      Backup-SP2013
    Author:    Travis Smith
	Author:    Tim Hansen
    LastEdit:  07/14/2015

#>
Function Backup-SP2013Farm {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("DirectoryName")]
        [System.String]
		$Name = "Farm",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7
	)
	BEGIN {
		if ( (Get-PSSnapin -Name Microsoft.SharePoint.Powershell -EA "SilentlyContinue") -eq $null )
		{
			Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction "SilentlyContinue"
		}
				
		Write-SP2013Verbose "Farm" "Starting" "SP Farm Backup Beginning..."
		if ($Name) {
			$FarmPath = "$Path\$Name"
		}
		
		Create-SP2013BackupDirectory $FarmPath
		$BackupPath = Get-SP2013Directory $FarmPath
		
		Write-SP2013Verbose "Farm" "Starting" "Backing up SP2013 Farm to $FarmPath"
		
		$eSubject = $SP2013SubjectPrefix
	}
	PROCESS {
		# Perform the backup
		Try
		{
			Write-SP2013Verbose "Farm" "Processing" "Beginning backup..."
			
			# Run a new full farm backup
			Backup-SPFarm -Directory $BackupPath -BackupMethod Full -ErrorAction Stop -Verbose:$Verbose -Percentage 15
		}
		Catch [system.exception]   # check for exceptions
		{
			Write-SP2013Verbose "Farm" "Processing" "Backup Failed!" -ForegroundColor "Red"
			
			# save off the exception message
			$eBody = $_.Exception.Message
			
			# new email subject
			$eSubject += "Backup Failed"
			
			# send an email containing the backup failure
			Send-SP2013BackupEmail $From $To $eSubject $eBody $SMTPHost "none" -Versbose:$Verbose
			
			# halt the script so we preserve older backups
			break
		}
		
		# Clean up Old Backups
		Clean-SP2013FarmBackups -Path $FarmPath -SPBRTOCLocation "$FarmPath\spbrtoc.xml" -Days $Days

		## Check backup progress and rip status when complete ##
		Write-SP2013Verbose "Farm" "Processing" "Monitoring backup..."
		$start = Get-Date
		
		# wait 15s for backup to initialize and restore log to be created
		Sleep 15
		$time = New-TimeSpan $start (Get-Date)
		Write-SP2013Verbose "Farm" "Processing" "Still monitoring. It's only been " + $time.TotalSeconds + "s..."
		
		# find last backup directory
		$lastBackupDir = gci $FarmPath | ? { $_.PSIsContainer } | sort -prop LastWriteTime | select -last 1
		
		# grab the backup log file from that directory
		$backupLogFile = $FarmPath + "\" + $lastBackupDir.Name + "\spbackup.log"
		
		# Check for Backup Completion!
		do
		{
			$time = New-TimeSpan $start (Get-Date)
			Write-SP2013Verbose "Farm" "Processing" "Still monitoring. It's only been " + $time.TotalSeconds + "s..."
			
			# Check for line at the end of the backup script (I would check for failures as well, but I've yet to see a failure to know what the output looks like.)
			$backupStatus = gc $backupLogFile | Select-String "Backup completed successfully." -Quiet
			
		} while ($backupStatus -eq $null)

		Write-SP2013Verbose "Farm" "Processing" "Monitoring Complete!" -ForegroundColor "Green"
	}
	END {
		Write-SP2013Verbose "Farm" "Ending" "SP Farm Backup Complete" -ForegroundColor "Green"
		
		# The backup status is saved in the last 4 log lines from the file. Save that information off
		$eBody += (gc $backupLogFile)[-2 .. -4]
		
		# Send Email Status
		Write-SP2013Verbose "Farm" "Ending" "Sending the email!"
		Send-SP2013BackupEmail $SP2013From $SP2013To $eSubject $eBody $SP2013SMTPHost $backupLogFile -Versbose:$Verbose
	}
}

# Clean-SP2013FarmBackups -Path $Path -SPBRTOCLocation $SPBRTOC -Days 7
Function Clean-SP2013FarmBackups {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("SPBRTOCLocation")]
        [System.String]
		$SPBRTOC,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7
	)
	BEGIN {
		Write-SP2013Verbose "Farm - Clean" "Starting" "Beginning to clean up old Farm backups"
		if (!$Path -and $SP2013Path)
		{
			$Path = $SP2013Path
		}
	}
	PROCESS {
		# Import the SharePoint backup report xml file
		Write-SP2013Verbose "Farm - Clean" "Processing" "Importing the SharePoint Backup Report XML File"
		[xml]$sp = gc $SPBRTOC
		
		# Find the old backups in spbrtoc.xml
		Write-SP2013Verbose "Farm - Clean" "Processing" "Finding Old Farm backups"
		$old = $sp.SPBackupRestoreHistory.SPHistoryObject | ? { $_.SPStartTime -lt ((Get-Date).adddays(-$Days)) }
		if ($old -ne $null) 
		{
			if ($Verbose)
			{
				$old | % { Write-SP2013Verbose "Farm - Clean" "Processing" "Deleting" + $_.SPBackupDirectory }
			}
			
			# Delete the old backups from the SharePoint backup report xml file
			$old | % { $sp.SPBackupRestoreHistory.RemoveChild($_) }
			
			# Delete the physical folders in which the old backups were located
			$old | % { Remove-Item $_.SPBackupDirectory -Recurse }
			
			# Save the new SharePoint backup report xml file
			Write-SP2013Verbose "Farm - Clean" "Processing" "Saving the SharePoint Backup Report XML File"
			$sp.Save($SPBRTOC)
		}
	}
}

Function Backup-SP2013Sites {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("DirectoryName")]
        [System.String]
		$Name = "Sites",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Collections.ArrayList]
        $Sites,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7
	)
	BEGIN {
		if ( (Get-PSSnapin -Name Microsoft.SharePoint.Powershell -EA "SilentlyContinue") -eq $null )
		{
			Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction "SilentlyContinue"
		}
		
		Write-SP2013Verbose "Sites" "Starting" "Backing up SP2013 Site Collections"
		
		# Get/Set path
		if (!$Path -and $SP2013Path)
		{
			$Path = $SP2013Path
		}
		
		# Get sites
		if (!$sites) {
			Write-SP2013Verbose "Sites" "Starting" "Getting ALL sites!"
			$Sites = get-spsite -Limit all
		}
		
		Write-SP2013Verbose "Sites" "Starting" "Sorting sites from largest to smallest by DiskSizeRequired"
		$Sites = $Sites | Sort-Object  ContentDatabase.DiskSizeRequired
		
		if ($Name) {
			$SitesPath = "$Path\$Name"
		}
		
		Create-SP2013BackupDirectory $SitesPath
		
		$BackupPath = Get-SP2013Directory $SitesPath
		
		Write-SP2013Verbose "Sites" "Starting" "Backing up SP2013 Farm to $SitesPath"
	}
	PROCESS {
		foreach ($site in $Sites)
		{
		   $BackupPath = $site.PrimaryUri.Host
		   if ($site.PrimaryUri.Segments.Length -gt 1)
		   {
			   $BackupPath += "." + $site.PrimaryUri.Segments[1].TrimEnd("/")
			   if ($site.PrimaryUri.Segments.Length -gt 2)
			   {
				   $BackupPath += "." + $site.PrimaryUri.Segments[2]
			   }
		   }
		   
		   Write-SP2013Verbose "Sites" "Processing" "Backing up $($site.Url) to $BackupPath\$BackupPath.bak"
		   
		   # Take the site backup without locking the site (-NoSiteLock) and using SQL snapshot
		   Backup-SPSite -Identity $site.id -Path "$BackupPath\$BackupPath.bak" -NoSiteLock -UseSqlSnapshot -Verbose:$Verbose
		}  
	}
	END {
		Write-SP2013Verbose "Sites" "Ending" "Cleaning old Site Collection Backups"
		Clean-SP2013Sites -Path $SitesPath - Days $Days
	}
}

Function Clean-SP2013Sites {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7
	)
	BEGIN {
		Write-SP2013Verbose "Sites - Clean" "Starting" "Cleaning up SP2013 Site Collection Backups"
		
		# Get/Set path
		if (!$Path -and $SP2013Path)
		{
			$Path = $SP2013Path
		}
	}
	PROCESS {
		# Remove old backup directories
		$old = gci $Path | ? { $_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) }
		
		# Check if old directories exist
		if ($old -eq $null) 
		{
			# Do Nothing
			break
		}
		
		# Remove Old Directories
		if ($Verbose)
		{
			$old | % { Write-SP2013Verbose "Sites - Clean" "Processing" "Removing " + $_.FullName }
		}
		$old | % { Remove-Item $_.FullName -Recurse }
	}
}

Function Backup-SP2013ServiceApplications {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("DirectoryName")]
        [System.String]
		$Name = "ServiceApplications",
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.Int32]
		$Days = 7
	)
	BEGIN {
		if ( (Get-PSSnapin -Name Microsoft.SharePoint.Powershell -EA "SilentlyContinue") -eq $null )
		{
			Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction "SilentlyContinue"
		}
		
		Write-SP2013Verbose "ServiceApps" "Starting" "Beginning SP Service Applications Backup"
		
		# Create SP Config Backup Directory
		if ($Name)
		{
			$SAPath = "$Path\$Name"
		}
		else
		{
			$SAPath = $Path
		}
		Create-SP2013BackupDirectory $SAPath
		$BackupPath = Get-SP2013Directory $SAPath
		
	}
	PROCESS {
		Write-SP2013Verbose "ServiceApps" "Processing" "Backing up SP Service Applications to $BackupPath"
		Backup-SPFarm -Directory $BackupPath -BackupMethod Full -Item "Farm\Shared Services" -Verbose:$Verbose -Percentage 15
	}
	END {
		Write-SP2013Verbose "Config" "Ending" "SP Service Applications Backup Complete" -ForegroundColor "Green"
	}
}

Function Create-SP2013BackupDirectory {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("Directory")]
        [System.String]
		$Path,
		
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [Alias("DirectoryName")]
        [System.String]
		$Name
	)
	BEGIN {
		$today = Get-SP2013Date
	}
	PROCESS {
		if ($Name)
		{
			Write-Verbose "Creating Directory $Path\$Name\$today"
			New-Item $Path\$Name\$today -Type directory
		}
		Else
		{
			Write-Verbose "Creating Directory $Path\$today"
			New-Item $Path\$today -Type directory
		}
	}
}

Function Get-SP2013Date {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$Format = "yyyyMMdd.HHmmss"
	)
	$today = Get-Date -Format $Format
	Set-Variable -Name "SP2013Today" -Value $today -Scope Global
	Return $today
}

Function Get-SP2013Directory {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $false,
			Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$Path
	)
	if (!$Path -and $SP2013Path) {
		Return $SP2013Path + "\" + (Get-SP2013Date)
	}
	Return $Path + "\" + (Get-SP2013Date)
}

# Email status when completed
# @todo Use an array for Send-Message
<#
	@{
		Subject = "Backup Failed: Farm Configuration Database"
		Body = "ERROR $_."
		From = $FromAddress
		To = $AdminEmail
		SmtpServer = $MailServer
	}
	[Parameter(
		Mandatory = $true,
		ValueFromPipeline = $true,
		ValueFromPipelinebyPropertyName = $true)]
	[Alias("Mail")]
	[System.Collections.ArrayList]
	$Mail
#>
Function Send-SP2013BackupEmail {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
			Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Sender")]
        [System.String]
		$From,
		
		[Parameter(
            Mandatory = $true,
			Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Recipients")]
        [System.String]
		$To,
		
		[Parameter(
            Mandatory = $true,
			Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$Subject,
		
		[Parameter(
            Mandatory = $true,
			Position = 3,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Message")]
        [System.String]
		$Body,
		
		[Parameter(
            Mandatory = $true,
			Position = 4,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("SMTP")]
        [System.String]
		$SMTPHost,
		
		[Parameter(
            Mandatory = $false,
			Position = 5,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Attachment")]
        [System.String]
		$AttachmentName
	)
	PROCESS {
		# check for an attachment (successful backup)
		if ($AttachmentName -ne "none")
		{
			# send email with attachment
			Send-MailMessage -from $from -to $to -Subject $subject -body $body -SmtpServer $SMTPHost -Attachments $AttachmentName -Verbose:$Verbose
		}
		else
		{
			# send email sans attachment
			Send-MailMessage -from $from -to $to -Subject $subject -body $body -SmtpServer $SMTPHost -Verbose:$Verbose   
		}
	}
}

Function Write-SP2013Verbose {
	[CmdletBinding()]
	param(
		[Parameter(
            Mandatory = $true,
			Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Name")]
        [System.String]
		$Namespace,
		
		[Parameter(
            Mandatory = $true,
			Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Stage")]
        [System.String]
		$Step,
		
		[Parameter(
            Mandatory = $true,
			Position = 2,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
		[Alias("Msg")]
        [System.String]
		$Message,
		
		[Parameter(
            Mandatory = $false,
			Position = 3,
            ValueFromPipeline = $true,
            ValueFromPipelinebyPropertyName = $true)]
        [System.String]
		$ForegroundColor
	)
	$Step = $Step.ToUpper();
	Write-Verbose "[$Namespace] ${Step}: $Message"
}
