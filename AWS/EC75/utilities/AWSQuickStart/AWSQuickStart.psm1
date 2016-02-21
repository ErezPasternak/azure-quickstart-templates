function New-AWSQuickStartWaitHandle {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [string]
        $Handle,

        [Parameter(Mandatory=$false)]
        [string]
        $Path = 'HKLM:\SOFTWARE\AWSQuickStart\'
    )

    process {
        try {
            Write-Verbose "Creating $Path"
            New-Item $Path -ErrorAction Stop

            Write-Verbose "Creating Handle Registry Key"
            New-ItemProperty -Path $Path -Name Handle -Value $Handle -ErrorAction Stop  
            
            Write-Verbose "Creating ErrorCount Registry Key"
            New-ItemProperty -Path $Path -Name ErrorCount -Value 0 -PropertyType dword -ErrorAction Stop                  
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
    }
}

function Get-AWSQuickStartErrorCount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]
        $Path = 'HKLM:\SOFTWARE\AWSQuickStart\'
    )

    process {
        try {            
            Write-Verbose "Getting ErrorCount Registry Key"
            Get-ItemProperty -Path $Path -Name ErrorCount -ErrorAction Stop | Select-Object -ExpandProperty ErrorCount                 
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
    }
}

function Set-AWSQuickStartErrorCount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [int32]
        $Count,

        [Parameter(Mandatory=$false)]
        [string]
        $Path = 'HKLM:\SOFTWARE\AWSQuickStart\'
    )

    process {
        try {  
            $currentCount = Get-AWSQuickStartErrorCount
            $currentCount += $Count
                      
            Write-Verbose "Creating ErrorCount Registry Key"
            Set-ItemProperty -Path $Path -Name ErrorCount -Value $currentCount -ErrorAction Stop                  
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
    }
}

function Get-AWSQuickStartWaitHandle {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [string]
        $Path = 'HKLM:\SOFTWARE\AWSQuickStart\'
    )

    process {
        try {
            Write-Verbose "Getting Handle key value from $Path"
            Get-ItemProperty $Path -ErrorAction Stop | Select-Object -ExpandProperty Handle        
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
    }
}

function Write-AWSQuickStartEvent {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName=$true)]
        [string]
        $Message,

        [Parameter(Mandatory=$false)]
        [string]
        $EntryType = 'Error'
    )

    process {
        Write-Verbose "Checking for AWSQuickStart Eventlog Source"
        if(![System.Diagnostics.EventLog]::SourceExists('AWSQuickStart')) {
            New-EventLog -LogName Application -Source AWSQuickStart -ErrorAction SilentlyContinue
        }
        else {
            Write-Verbose "AWSQuickStart Eventlog Source exists"
        }   
        
        Write-Verbose "Writing message to application log"   
           
        try {
            Write-EventLog -LogName Application -Source AWSQuickStart -EntryType $EntryType -EventId 1001 -Message $Message
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
    }
}

function Write-AWSQuickStartException {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline=$true)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    process {
        $handle = Get-AWSQuickStartWaitHandle

        Write-Verbose "Incrementing error count"
        Set-AWSQuickStartErrorCount -Count 1

        Write-Verbose "Getting total error count"
        $errorTotal = Get-AWSQuickStartErrorCount

        $errorMessage = "Command failure in {0} {1} on line {2}" -f $ErrorRecord.InvocationInfo.MyCommand.name, 
                                                              $ErrorRecord.InvocationInfo.ScriptName, $ErrorRecord.InvocationInfo.ScriptLineNumber

        try {
            Invoke-Expression "cfn-signal.exe -e 1 --reason='$errorMessage' `"$handle`""
        }
        catch {
            Write-Verbose $_.Exception.Message
        }

        Write-AWSQuickStartEvent -Message $errorMessage        
    }
}

function Write-AWSQuickStartStatus {
    [CmdletBinding()]
    Param()

    process {   
        try {
            Write-Verbose "Checking error count"
            if((Get-AWSQuickStartErrorCount) -eq 0) {
                Write-Verbose "Getting Handle"
                $handle = Get-AWSQuickStartWaitHandle 
                Invoke-Expression "cfn-signal.exe -e 0 `"$handle`""
            }
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
    }
}

