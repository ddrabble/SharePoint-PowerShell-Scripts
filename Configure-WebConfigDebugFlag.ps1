function Get-WebConfigDebugFlag {
    PARAM(
        [string[]]$Path
    )
    foreach($Folder in $Path) {
        Get-ChildItem $Folder -Recurse -Include 'web.config' | ForEach-Object { 
        if (Test-Path -Path $_ -PathType Leaf) {
            $DebugFlag = (([xml](Get-Content -Path $_)).configuration.'system.web'.compilation.debug)
            if (!$DebugFlag) { $DebugFlag = $null }
                New-Object -TypeName PSObject -Property @{'Path'=$_; 'DebugFlag'=$DebugFlag}
            }
        }
    }
}

function Set-WebConfigDebugFlag {
    PARAM(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Path,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        $DebugFlag = $false
    )

    process {
        foreach($Folder in $Path) {
            Get-ChildItem $Folder -Recurse -Include 'web.config' | ForEach-Object { 
            
            if (Test-Path -Path $_ -PathType Leaf) {
                $config = ([xml](Get-Content -Path $_))

                try {
                    if (($config.SelectSingleNode('configuration/system.web/compilation')) -eq $null) {
                        $compilation = $config.CreateElement('compilation')
                        $sw = $config.SelectSingleNode('configuration/system.web')
                        [void] $sw.AppendChild($compilation)
                    } 
                        
                    if ($config.SelectSingleNode('configuration/system.web/compilation/debug') -eq $null) {
                        $compilation = $config.SelectSingleNode('configuration/system.web/compilation')
                        $compilation.SetAttribute('debug', ($DebugFlag.ToString()).ToLower())
                    } else { 
                        $config.configuration.'system.web'.compilation.debug = $DebugFlag 
                    }

                    $config.Save($_)
                    if($?) { 
                        $Result = 'Success' 
                        $ThisDebugFlag = $DebugFlag
                    } else { 
                        $Result = 'Error saving the config file' 
                        $ThisDebugFlag = ''
                    }

                } catch {
                    $Result = $_.Exception.Message
                    if ($Result -eq 'You cannot call a method on a null-valued expression.') { 
                        $Result = "Configuration does not contain a 'system.web' section" 
                        $ThisDebugFlag = ''
                    }
                }
                New-Object -TypeName PSObject -Property @{'Path'=$_; 'DebugFlag'=$ThisDebugFlag; 'Result'=$Result }
                }
            }
        }
    }
}