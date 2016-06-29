<#
.Synopsis
   Gather Configuration Manager log files from remote systems
.DESCRIPTION
   The script uses PowerShell remoting to connect to the remote client, then creates a ZIP archive file remotely
   containing all Configuration Manager log files and then transfers the archive back. 
.EXAMPLE
   Get-RemoteCMLogs -Computer computer1, computer2
.NOTES
    Version 1.0
    Written by Alex Verboon, Zip function written by  Kenneth D. Sweet, Send-File function wirtten by lee holmes
    Requirements: WinRM must be enabled
#>
 
[cmdletbinding()]
 
Param(
 [Parameter(Mandatory=$True,Position=0)]
 [string[]]$Computername ="ec64.test.local"
  )
 
 
Function Get-EricomConnectLogs ($Computername) {
#--------------------------------------------------------------------------------------
# Global Variables
#--------------------------------------------------------------------------------------
# The location where the CM Agent log files are stored, will make this dynamic in a future release
# currently this relates to the CM12 Agent
$GridLogFldr = "C:\Program Files\Ericom Software\Ericom Connect Data Grid\NET v4.0\Logs"
$ESGLogFldr = "C:\Program Files\Ericom Software\Ericom Connect Secure Gateway\Logs"
$ASLogFldr = "C:\Program Files\Ericom Software\Ericom Access Server\logs"
$ECAPPDataLogFldr = "C:\ProgramData\EricomConnect\*.txt"

$ThisComputer = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName
#The folder where the log archive files are stored to
$localtmpfolder = "$env:USERPROFILE\Documents\EricomConnectLogs"
 
#Check if the RemoteCMlogs folder already exists othrwise create it
If (!(Test-path $localtmpfolder)) {New-Item -ItemType directory -Path $localtmpfolder}
 
$cred = Get-Credential
 
Function ZIP-EClogs  ($Computername, $ThisComputer,$cred,$localtmpfolder) {
 
#--------------------------------------------------------------------------------------
# ZIP File Function. Credits for this function go to Kenneth D. Sweet
 
# http://gallery.technet.microsoft.com/ZIP-Files-script-b5374a5d/view/Discussions#content
#--------------------------------------------------------------------------------------
Function Zip-File () {
  <#
    .SYNOPSIS
      Add, Removes, and Extracts files and folders to a Zip Archive
    .DESCRIPTION
      Add, Removes, and Extracts files and folders to a Zip Archive
    .PARAMETER ZipFile
      Name os Zip Archive
    .PARAMETER Add
      Names of Files or Folders to Add to Zip Archive
      Will not overwrite existing Files in the Zip Archive
      Will only add in Files from Sub Folders to the Zip Archive when you add a Folder
    .PARAMETER Remove
      Names of Files or Folders to Remove from Zip Archive
      If "Display Delete Confirmation" is enable you will be prompted confirm to Remove each File
    .PARAMETER Extract
      Names of Files or Folders to Extract from Zip Archive
      Recreates Folders structure when extracting Files, even Folders that have no Matching Files to Extract 
    .PARAMETER Destination
      Destination Folder to Extract Files or Folders to
    .PARAMETER Folders
      Add, Remove, or Extract Folders instead of Files from the Zip Archive
    .PARAMETER List
      List the Contents of the Zip Archive
    .INPUTS
    .OUTPUTS
    .NOTES
      Written by Kenneth D. Sweet CopyRight (c) 2012
      Add, Removes, and Extracts files and folders to a Zip Archive
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -Add "C:\Temp\Temp_01.txt", "C:\Temp\Temp_02.txt"
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -Add "C:\Temp_01", "C:\Temp_02" -Folders
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -Remove "*.xls", "*.xlsx"
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -Remove "Temp_01" -Folders
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -Extract "*.doc", "*.docx"-Destination "C:\Temp" 
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -Extract "Temp_02" -Destination "C:\Temp" -Folders
    .EXAMPLE
      Zip-File -ZipFile "C:\Test.zip" -List
    .LINK
      Ken Sweet Rules the MultiVerse
  #>
  [CmdletBinding(DefaultParameterSetName="Add")]
  Param(
    [Parameter(Mandatory=$True, ParameterSetName="Add")]
    [Parameter(Mandatory=$True, ParameterSetName="Remove")]
    [Parameter(Mandatory=$True, ParameterSetName="Extract")]
    [Parameter(Mandatory=$True, ParameterSetName="List")]
    [String]$ZipFile,
    [Parameter(Mandatory=$True, ParameterSetName="Add")]
    [String[]]$Add,
    [Parameter(Mandatory=$False, ParameterSetName="Add")]
    [Switch]$Recurse,
    [Parameter(Mandatory=$True, ParameterSetName="Remove")]
    [String[]]$Remove,
    [Parameter(Mandatory=$True, ParameterSetName="Extract")]
    [String[]]$Extract,
    [Parameter(Mandatory=$False, ParameterSetName="Extract")]
    [String]$Destination=$PWD,
    [Parameter(Mandatory=$False, ParameterSetName="Add")]
    [Parameter(Mandatory=$False, ParameterSetName="Remove")]
    [Parameter(Mandatory=$False, ParameterSetName="Extract")]
    [Switch]$Folders,
    [Parameter(Mandatory=$True, ParameterSetName="List")]
    [Switch]$List
  )
  DynamicParam {
    if ($ZipFile -match ".*Zip\\.*")  {
      $NewAttrib = New-Object -TypeName  System.Management.Automation.ParameterAttribute
      $NewAttrib.ParameterSetName = "List"
      $NewAttrib.Mandatory = $True
      $AttribCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
      $AttribCollection.Add($NewAttrib)
      $DynamicParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter("Path", [String], $AttribCollection)
      $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
      $paramDictionary.Add("Path", $DynamicParam)
      return $ParamDictionary
    }
  }
  Begin {
    $Shell = New-Object -ComObject Shell.Application
    if (![System.IO.File]::Exists($ZipFile) -and ($PSCmdlet.ParameterSetName -eq "Add")) {
      Try {
        [System.IO.File]::WriteAllText($ZipFile, $("PK" + [Char]5 + [Char]6 + $("$([Char]0)" * 18)))
      }
      Catch {
      }
    }
    $ZipArchive = $Shell.NameSpace($ZipFile)
    if ($PSCmdlet.ParameterSetName -eq "Add") {
      $TempFolder = "$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetRandomFileName())"
      if (![System.IO.Directory]::Exists($TempFolder)) {
        [Void][System.IO.Directory]::CreateDirectory($TempFolder)
      }
    }
  }
  Process {
    Switch ($PSCmdlet.ParameterSetName) {
      "Add" {
        Try {
          if ($Folders) {
            ForEach ($File in $Add) {
              $SearchPath = [System.IO.Path]::GetDirectoryName($File)
              $SearchName = [System.IO.Path]::GetFileName($File)
              $DirList = [System.IO.Directory]::GetDirectories($SearchPath, $SearchName)
              $Total = $ZipArchive.Items().Count
              ForEach ($Dir in $DirList) {
                $ParseName = $ZipArchive.ParseName([System.IO.Path]::GetFileName($Dir))
                if ([String]::IsNullOrEmpty($ParseName)) {
                  if (!$Recurse) {
                    # Write-Host "Adding Folder: $Dir " original line from zip function
                    Write-Host "Processing Computer: $Computername Adding Folder: $Dir to $filename" # customized message 
                  }
                  $ZipArchive.CopyHere($Dir, 0x14)
                  Do {
                    [System.Threading.Thread]::Sleep(100)
                  } While ($ZipArchive.Items().Count -eq $Total)
                } else {
                  if (!$Recurse) {
                    Write-Host "Folder Exists in Archive: $Dir"
                  }
                }
              }
            }
          } else {
            ForEach ($File in $Add) {
              $SearchPath = [System.IO.Path]::GetDirectoryName($File)
              $SearchName = [System.IO.Path]::GetFileName($File)
              $FileList = [System.IO.Directory]::GetFiles($SearchPath, $SearchName)
              $Total = $ZipArchive.Items().Count
              ForEach ($File in $FileList) {
                $ParseName = $ZipArchive.ParseName([System.IO.Path]::GetFileName($File))
                if ([String]::IsNullOrEmpty($ParseName)) {
                  Write-Host "Adding File: $File"
                  $ZipArchive.CopyHere($File, 0x14)
                  Do {
                    [System.Threading.Thread]::Sleep(100)
                  } While ($ZipArchive.Items().Count -eq $Total)
                } else {
                  Write-Host "File Exists in Archive: $File"
                }
              }
              if ($Recurse) {
                $DirList = [System.IO.Directory]::GetDirectories($SearchPath)
                ForEach ($Dir in $DirList) {
                  $NewFolder = [System.IO.Path]::GetFileName($Dir)
                  if (!$ZipArchive.ParseName($NewFolder)) {
                    [Void][System.IO.Directory]::CreateDirectory("$TempFolder\$NewFolder")
                    [System.IO.File]::WriteAllText("$TempFolder\$NewFolder\.Dir", "")
                    Zip-File -ZipFile $ZipFile -Add "$TempFolder\$NewFolder" -Folders -Recurse
                  }
                  $NewAdd = @()
                  ForEach ($Item in $Add) {
                    $NewAdd += "$([System.IO.Path]::GetDirectoryName($Item))\$NewFolder\$([System.IO.Path]::GetFileName($Item))"
                  }
                  Zip-File -ZipFile "$ZipFile\$NewFolder" -Add $NewAdd -Recurse:$Recurse
                }
              }
            }
          }
        }
        Catch {
          Throw "Error Adding Files to Zip Archive"
        }
        Break
      }
      "Remove" {
        Try {
          ForEach ($File in $Remove) {
            if ($Folders) {
              $($ZipArchive.Items() | Where-Object -FilterScript { $_.IsFolder -and (($_.Name -eq $File) -or ($_.Name -match $File.Replace('.', '\.').Replace('*', '.*'))) }) | ForEach-Object -Process { Write-Host "Removing Folder: $($_.Name)"; $_.InvokeVerbEx("Delete", 0x14) }
            } else {
              $($ZipArchive.Items() | Where-Object -FilterScript { !$_.IsFolder -and (($_.Name -eq $File) -or ($_.Name -match $File.Replace('.', '\.').Replace('*', '.*'))) }) | ForEach-Object -Process { Write-Host "Removing File: $($_.Name)"; $_.InvokeVerbEx("Delete", 0x14) }
            }
          }
          ForEach ($Folder in $($ZipArchive.Items() | Where-Object -FilterScript { $_.IsFolder })) {
            Zip-File -ZipFile "$ZipFile\$($Folder.Name)" -Remove $Remove -Folders:$Folders
          }
        }
        Catch {
          Throw "Error Removing Files from Zip Archive"
        }
        Break
      }
      "Extract" {
        Try {
          if (![System.IO.Directory]::Exists($Destination)) {
            [Void][System.IO.Directory]::CreateDirectory($Destination)
          }
          $DestFolder = $Shell.NameSpace($Destination)
          ForEach ($File in $Extract) {
            if ($Folders) {
              $($ZipArchive.Items() | Where-Object -FilterScript { $_.IsFolder -and (($_.Name -eq $File) -or ($_.Name -match $File.Replace('.', '\.').Replace('*', '.*'))) }) | ForEach-Object -Process { Write-Host "Extracting Folder: $($_.Name) to $Destination"; $DestFolder.CopyHere($_, 0x14) }
            } else {
              $($ZipArchive.Items() | Where-Object -FilterScript { !$_.IsFolder -and (($_.Name -eq $File -and $_.Name -ne ".Dir") -or ($_.Name -match $File.Replace('.', '\.').Replace('*', '.*'))) }) | ForEach-Object -Process { Write-Host "Extracting File: $($_.Name) to $Destination"; $DestFolder.CopyHere($_, 0x14) }
            }
          }
          ForEach ($Folder in $($ZipArchive.Items() | Where-Object -FilterScript { $_.IsFolder })) {
            Zip-File -ZipFile "$ZipFile\$($Folder.Name)" -Extract $Extract -Destination "$Destination\$($Folder.Name)" -Folders:$Folders
          }
        }
        Catch {
        $Error[0]
          Throw "Error Extracting Files from Zip Archive"
        }
        Break
      }
      "List" {
        Try {
          $ZipArchive.Items() | Where-Object -FilterScript { !$_.IsFolder -and $_.Name -ne ".Dir" } | Select-Object -Property "Name", "Size", "ModifyDate", "Type", @{"Name"="Path";"Expression"={$(if ($($PSCmdlet.MyInvocation.BoundParameters["Path"])) {$($PSCmdlet.MyInvocation.BoundParameters["Path"])} else {"\"})}}
          ForEach ($Folder in $($ZipArchive.Items() | Where-Object -FilterScript { $_.IsFolder })) {
            Zip-File -ZipFile "$ZipFile\$($Folder.Name)" -List -Path "$(if ($($PSCmdlet.MyInvocation.BoundParameters["Path"])) {$($PSCmdlet.MyInvocation.BoundParameters["Path"])})\$($Folder.Name)"
          }
        }
        Catch {
          Throw "Error Listing Files in Zip Archive"
        }
        Break
      }
    }
  }
  End {
    $Shell = $Null
    $ZipArchive = $Null
    if ($PSCmdlet.ParameterSetName -eq "Add") {
      if ([System.IO.Directory]::Exists($TempFolder)) {
        [Void][System.IO.Directory]::Delete($TempFolder, $True)
      }
    }
  }
}
# end of ZIP-File Function
 
 
 
Function Send-File {
 
##############################################################################
##
## Send-File
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
## http://www.powershellcookbook.com/recipe/ISfp/program-transfer-a-file-to-a-remote-computer
##############################################################################
 
<#
 
.SYNOPSIS
 
Sends a file to a remote session.
 
.EXAMPLE
 
PS &gt;$session = New-PsSession leeholmes1c23
PS &gt;Send-File c:\temp\test.exe c:\temp\test.exe $session
 
#>
 
param(
    ## The path on the local computer
    [Parameter(Mandatory = $true)]
    $Source,
 
    ## The target path on the remote computer
    [Parameter(Mandatory = $true)]
    $Destination,
 
    ## The session that represents the remote computer
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.Runspaces.PSSession] $Session
)
 
 
 
Set-StrictMode -Version Latest
 
## Get the source file, and then get its content
$sourcePath = (Resolve-Path $source).Path
$sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
$streamChunks = @()
 
## Now break it into chunks to stream
Write-Progress -Activity "Sending $Source" -Status "Preparing file"
$streamSize = 1MB
for($position = 0; $position -lt $sourceBytes.Length;
    $position += $streamSize)
{
    $remaining = $sourceBytes.Length - $position
    $remaining = [Math]::Min($remaining, $streamSize)
 
    $nextChunk = New-Object byte[] $remaining
    [Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
    $streamChunks += ,$nextChunk
}
 
$remoteScript = {
    param($destination, $length)
 
    ## Convert the destination path to a full filesytem path (to support
    ## relative paths)
    $Destination = $executionContext.SessionState.`
        Path.GetUnresolvedProviderPathFromPSPath($Destination)
 
    ## Create a new array to hold the file content
    $destBytes = New-Object byte[] $length
    $position = 0
 
    ## Go through the input, and fill in the new array of file content
    foreach($chunk in $input)
    {
        Write-Progress -Activity "Writing $Destination" `
            -Status "Sending file" `
            -PercentComplete ($position / $length * 100)
 
        [GC]::Collect()
        [Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
        $position += $chunk.Length
    }
 
    ## Write the content to the new file
    [IO.File]::WriteAllBytes($destination, $destBytes)
 
    ## Show the result
    Get-Item $destination
    [GC]::Collect()
}
 
## Stream the chunks into the remote script
$streamChunks | Invoke-Command -Session $session $remoteScript `
    -ArgumentList $destination,$sourceBytes.Length
 
 
}
### End of Send-File function
 
 
# -----------------------------------------------------------------------------------------------------------------------#
# Below are the commands we execute remotely
# -----------------------------------------------------------------------------------------------------------------------#
 
# Get the Windows Temp folder on the remote system
$tmpfolder = "$env:SystemRoot\TEMP\"
# create timestamp variable 
$timestamp = $((get-date).tostring("MMddyyyyHHmmss"))
# construct the filename including the path
$filename =  "ECLogs_" + $Computername + "_" + $timestamp + ".zip"

$ECtmpfolder = "$env:SystemRoot\TEMP\ECLogs_"+ $Computername + "_" + $timestamp
$GridLogFldr = "C:\Program Files\Ericom Software\Ericom Connect Data Grid\NET v4.0\Logs"
$ESGLogFldr = "C:\Program Files\Ericom Software\Ericom Connect Secure Gateway\Logs"
$ASLogFldr = "C:\Program Files\Ericom Software\Ericom Access Server\logs"
$ECAPPDataLogFldr = "C:\ProgramData\EricomConnect\*.txt"
$ConnectCLIPath = "\Ericom Software\Ericom Connect Configuration Tool\ConnectCLI.exe"

# getting the logs from all folders 
Copy-Item -Path $GridLogFldr -Destination "$ECtmpfolder\Grid" -Recurse
Copy-Item -Path $ESGLogFldr -Destination "$ECtmpfolder\ESG" -Recurse
Copy-Item -Path $ASLogFldr -Destination "$ECtmpfolder\AS" -Recurse

New-Item -Path "$ECtmpfolder\AppData" -ItemType  Directory
Copy-Item -Path $ECAPPDataLogFldr -Destination "$ECtmpfolder\AppData" -Recurse

New-Item -Path "$ECtmpfolder\CLILogs" -ItemType  Directory

 $logsPath = "$ECtmpfolder\CLILogs\"   
    $configPath = Join-Path $env:ProgramFiles -ChildPath $ConnectCLIPath.Trim()
    $user = "admin@test.local"
    $pass = "admin"
	
    & $configPath systeminfo localhost > $logsPath\systemInfo.txt
    & $configPath GridInfo  > $logsPath\GridInfo.txt
    & $configPath ESGconfig /adminuser $user /adminpassword $pass common  > $logsPath\ESGInfo.txt
    & $configPath EUWSconfig /adminuser $user /adminpassword $pass common  > $logsPath\EUWSInfo.txt



# Generate ZIP file with content from temp log folder.
If (Test-path $ECtmpfolder) {zip-file -ZipFile "$ECtmpfolder$filename" -Add $ECtmpfolder -Folders} Else {Write-Warning "Could not find folder" $ECtmpfolder}
 

# On the remote machine, start a new remote session back to the script execution host
$RSession = New-PSSession $ThisComputer -Credential $cred
# Transfer the logs archive through the open session
Send-File "$ECtmpfolder$filename" "$localtmpfolder\$filename" $RSession
# close the session from the remote host to the script execution host
Remove-PSSession $RSession
 
}
# End of ZIP-EClogs function
 
# -----------------------------------------------------------------------------------------------------------------------#
# Commands from Get-EricomConnectLogs Main function
# -----------------------------------------------------------------------------------------------------------------------#
# Process all computers provided
ForEach ($iComputername in $Computername)
{
    Function Get-Remotelogs {
    # Settings this option prevents the creation of the user profile on the remote system 
    $SesOpt = New-PSSessionOption -NoMachineProfile 
    # Start a new Remote Session
    $ses = New-PSSession -ComputerName $iComputername -ErrorAction SilentlyContinue -SessionOption $SesOpt
    # Execute the ZIP-EClogs function on the remote machine. 
    $ab = Invoke-Command -Session $ses -ScriptBlock ${function:ZIP-EClogs} -ArgumentList $iComputername, $ThisComputer,$cred,$localtmpfolder
    # Clsoe the session
    Remove-PSSession $ses
    }
 
Get-Remotelogs $iComputername
}
 
}
# End of Get-EricomConnectLogs function
 
# -----------------------------------------------------------------------------------------------------------------------#
 
Get-EricomConnectLogs $Computername
