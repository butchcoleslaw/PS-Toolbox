# #############################################################################
# LISTO SYSTEMS, LLC
# NAME: Mirror-Folder.ps1
# 
# AUTHOR:  Ken Friddle, Listo Systems, LLC
# DATE:  2019/12/01
# EMAIL: ListoSystems@gmail.com
# 
# COMMENT:  This script will mirror the contents of one folder to another.
# Note that this is a ONE-WAY mirror, meaning all adds and deletes in the
# source folder are replicated to the target folder; however, any updates
# and adds in the target folder are not copied back to the source.
#
# VERSION HISTORY
# 1.0 2019.12.01 Initial Version.
#
# TO ADD
# -Currently this version only handles a local source folder and a remote target folder.
#  As such, this script assumes credentials are necessary and uses credentials when 
#  creating the PSDrive to the target folder.
#  A future enhancement would be to detect if the target folder is local, and not create
#  a PSDrive for the target folder if local. This is why the $CredsPath parameter is not
#  mandatory.
#
# -Related to the above enhancement, you could still have a remote target folder, but not
#  need credentials. This is possible if the current account is already provisioned on the
#  remote computer. With or without a credential can be handled by splatting the parameters.
#
# -Currently this version only checks for changes in file name and/or length. A better option
#  would be to also compare the file hashes for those files that are equal name and equal length.
#  This could be a very time consuming process for folders with many files (gt 1000 files).
#  Therefore, a future enhancement would be to add a switch to compare file hashes.
#  If you are comparing file hashes, then you can be sure you can update files from source to
#  target that are different, but yet their name and length remained the same.
#
# -Another future enhancement would be to read a list of file names to always copy from source
#  to target. This would be a new optional parameter of a path to the text file list of names.
#  This list would be useful if you are using a file watcher on the source path to detect file
#  changes. If your separate file watcher (not included) generates a list of files, then you 
#  could be sure to get those files that changed, yet have the same name and length. And you 
#  would not need to use a lengthy hash process on a folder that has a lot of files.
#
# -Add a file spec option to only mirror those files that match the spec.
#  For example, mirror only the *.log files, or *.txt and MyZip.* files.
#  Current version mirrors all files in the folder.
#
# TODO: 
# -Update various comments and documentation.
#
#
#
#
#
#
# -Fix the...
# #############################################################################
<#
.SYNOPSIS
  This script will mirror a source folder to a target folder.

.DESCRIPTION
  This script attempts a one-way mirror from a source folder to a target folder.
  There are a lot of short-comings with this version of the script.
  For example, this script
  DOES...
       assume the target folder is remote;
       assume you need credentials to connect to the remote folder;
       assume your credentials file is a valid xml credential file;
       only pick up file differences by name and length;

  DOES NOT...
       detect changes by comparing file hashes;
       perform two-way file mirroring - only source to target;
       mirror based on file spec, e.g. *.txt,*.log

.PARAMETER SourcePath
    This is the path for the source of files you wish to mirror.

.PARAMETER TargetPath
    This is the path you wish to mirror to. Currently only works with \\servername\path folders.

.PARAMETER CredsPath
    Path and file name of a valid xml file that stores credentials to the remote folder.
    This file was previously created using the following code:
        Get-Credential | Export-Clixml -Path 'path to saved credentials'

.INPUTS
  None, other than parameters mentioned above

.OUTPUTS
  Log file stored in $ThisScriptPath\Logs\${BatchID}_$ThisScriptBaseName.log

.NOTES
  Version:        1.0
  Author:         Ken Friddle
  Creation Date:  01-Dec 2019
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
  .\Mirror-Folder.ps1 -SourcePath "X:\DataBackups\Coulson\Genie_Timeline" `
  -TargetPath "\\FITZ\DataBackups_Coulson\Genie_Timeline" `
  -CredsPath "C:\Util\PSCredsFSM.xml"
#>

[CmdletBinding()]

PARAM (
    # Full Path to the local folder you wish to mirror
    [Parameter(Mandatory=$true)]
    [Alias("Source")]
    [string]$SourcePath,

    # The full path to the Target location to mirror to.
    [Parameter(Mandatory=$true)]
    [Alias("Target")]
    [string]$TargetPath,

    # The full path to the Credentials file you wish to copy to a remote location.
    [Parameter(Mandatory=$false)]
    [Alias("CredentialsFile")]
    [string]$CredsPath = $null,

    # If source is empty and action results in full deletion of target, do you want to proceed?
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,

    # Do you want status messages echoed to the screen?
    [Parameter(Mandatory=$false)]
    [switch]$ToScreen = $false
)

#---------------------------------------------------------[Initializations]--------------------------------------------------------

#region Initializations
#Set Error Action to Silently Continue
#$ErrorActionPreference = "SilentlyContinue"
#$VerbosePreference = "Continue"

$ThisScriptName = $MyInvocation.MyCommand.Name
$ThisScriptBaseName = (Get-Item $ThisScriptName).BaseName
$ThisScriptPath = $PSScriptRoot
$PSFunctionsPath = (Join-Path -Path $ThisScriptPath -ChildPath "PSFunctions")
$PSModulesPath = (Join-Path -Path $ThisScriptPath -ChildPath "PSModules")
$originalLocation = Get-Location
Set-Location -Path "$ThisScriptPath"
Write-Verbose "ThisScriptName is $ThisScriptName"
Write-Verbose "ThisScriptBaseName is $ThisScriptBaseName"
Write-Verbose "ThisScriptPath is $ThisScriptPath"
Write-Verbose "PSFunctionsPath is $PSFunctionsPath"
Write-Verbose "PSModulesPath is $PSModulesPath"
#endregion Initializations

#region Dot Source Functions
#Dot Source required Function Libraries
$AllFunctionsFound = $true
$MsgFunctionNotFound = "The following functions were not found: `n"
### dot-source a function
$CurrentFunction = "Get-BatchID.ps1"
if (!(Test-Path -Path "$PSFunctionsPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$PSFunctionsPath\$CurrentFunction"
}
## Repeat above code for each function to dot-source
## Finally...

# If any of the dot sourced functions are missing, write out error message and exit
if (!($AllFunctionsFound)) {
    Write-Error $MsgFunctionNotFound -Category ObjectNotFound
    Exit
}
#endregion Dot Source Functions

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#region Declarations
#Script Version
$sScriptVersion = "1.0"
$BatchID = Get-BatchID
Write-Verbose "BatchID is $BatchID"

#Log File Info
$LogFileName = "${BatchID}_$ThisScriptBaseName.log"
$LogFileParentPath = Join-Path $ThisScriptPath -ChildPath "Logs"
$LogFile = Join-Path -Path $LogFileParentPath -ChildPath $LogFileName
if (!(Test-Path -Path $LogFileParentPath)) {
    New-Item -Path $LogFileParentPath -ItemType Directory | Out-Null
}
Write-Verbose "Logfile name is $LogFile"
#endregion Declarations
#-----------------------------------------------------------[Import-Module]------------------------------------------------------------
#region Import-Module
Write-Verbose "Entering Import-Module section"
# Import EZLog module for script logging...
switch ($PSVersionTable.PSVersion.Major) {
    "4" {$PoShv = "PoShv4"}
    "5" {$PoShv = "PoShv5"}
    "6" {$PoShv = "PoShv5"}
    "7" {$PoShv = "PoShv5"}
}
$ModuleName = "EZLog"
$ModuleVersion = $PoShv
$ModulePath = Join-Path -Path "$PSModulesPath" -ChildPath "$ModuleName" | Join-Path -ChildPath "$ModuleVersion" | Join-Path -ChildPath "$ModuleName.psm1"
Write-Verbose "Looking for $ModulePath"
if (Test-Path -Path "$ModulePath" -PathType Leaf) {
    Write-Verbose "Attempting to import module $ModuleName"
    Import-Module -Name "$ModulePath" -Force
} else {
    Write-Verbose "Missing module '$ModuleName'. Please fix then try again."
    Write-Error -Message "Missing module '$ModuleName'. Please fix then try again." -Category ObjectNotFound
    Exit
}
Write-Verbose "Completed importing the $ModuleName module."

Write-Verbose "Exiting Import-Module"
#endregion Import-Module

#-----------------------------------------------------------[Functions]------------------------------------------------------------
#region Functions
Write-Verbose "Entering Functions"

<#

Function <FunctionName> {
<#
.SYNOPSIS
   Function that 

.DESCRIPTION
   This function allows .... 

   Furthermore it .....

.PARAMETER Parameter1
    Specify the log file's path.

.EXAMPLE
   Function-name -Parameter1 C:\temp\mylog.log

   Returns an object from the log file.

.NOTES
   AUTHOR: Ken Friddle
   LASTEDIT: 2019/11/15

[CmdletBinding()]
    Param ( 
       [parameter(Mandatory=$true, ValueFromPipeline=$true, position=0)]
       [Alias("Path")]
       [string]$FilePath

     #  [parameter(Mandatory=$false, ValueFromPipeline=$false)]
     #  [switch]$ToJson
    )

  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      <code goes here>
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
    Return $value
}

#>

Function Create-RemoteDrive {
<#
.SYNOPSIS
   Function that 

.DESCRIPTION
   This function allows .... 

   Furthermore it .....

.PARAMETER Parameter1
    Specify the log file's path.

.EXAMPLE
   Function-name -Parameter1 C:\temp\mylog.log

   Returns an object from the log file.

.NOTES
   AUTHOR: Ken Friddle
   LASTEDIT: 2019/11/15

<#
.SYNOPSIS
   Function that 

.DESCRIPTION
   This function allows .... 

   Furthermore it .....

.PARAMETER Parameter1
    Specify the log file's path.

.EXAMPLE
   Function-name -Parameter1 C:\temp\mylog.log

   Returns an object from the log file.

.NOTES
   AUTHOR: Ken Friddle
   LASTEDIT: 2019/12/06

#>
[CmdletBinding()]
    Param ( 
       [parameter(Mandatory=$true, position=0)]
       [string]$TargetPath

    )
    $TargetPathParent = ($TargetPath -split '\\' | select -SkipLast 1) -join '\'
    $Tries = 0
    Do {
        $Tries++
        try {
            $Msg = "Attempting to create remote drive, try #$Tries."
            Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
            ###Write-Verbose "$Msg"
            New-PSDrive -Name target -PSProvider FileSystem -Credential $Credential -Root "$TargetPath" -Description "Target folder" -Scope 1 -ErrorAction Stop | Out-Null
            $Tries++
        } #try #1
        catch {
            $Msg = "Unable to find target folder $TargetPath."
            Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
            ###Write-Verbose "$Msg"
            try {
                $Msg = "Attempting to create remote drive to $TargetPathParent."
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                New-PSDrive -Name targetparent -PSProvider FileSystem -Credential $Credential -Root "$TargetPathParent" -Description "Target folder parent" -ErrorAction Stop | Out-Null
                New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
                Remove-PSDrive -Name targetparent -Force
            } #try #2
            catch {
                $Msg = "Unable to create remote drive to $TargetPathParent."
                Write-EZLog -Category ERR -Message "$Msg" -ToScreen
                ###Write-Verbose "$Msg"
                $Tries = 50
            } #catch #2
        } #catch #1
    } #Do loop
    Until ($Tries -gt 1)

    if (Test-Path target:\) {
        $Msg = "Remote drive to $TargetPath was successfully created."
        Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
        ###Write-Verbose "$Msg"
        return $true
    } else {
        $Msg = "Remote drive to $TargetPath failed to be created."
        Write-EZLog -Category ERR -Message "$Msg" -ToScreen
        ###Write-Verbose "$Msg"
        return $false
    } #if/else

} #function Create-RemoteDrive


Function Mirror-FileItems {
<#
.SYNOPSIS
   Function that 

.DESCRIPTION
   This function allows .... 

   Furthermore it .....

.PARAMETER Parameter1
    Specify the log file's path.

.EXAMPLE
   Function-name -Parameter1 C:\temp\mylog.log

   Returns an object from the log file.

.NOTES
   AUTHOR: Ken Friddle
   LASTEDIT: 2019/12/06
#>

[CmdletBinding()]
    Param ( 
       [parameter(Mandatory=$true, position=0)]
       [PsCustomObject]$SourceFiles,

       [parameter(Mandatory=$true, position=1)]
       [PsCustomObject]$TargetFiles

    )
    try {
        Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $targetFiles -Property ('ShortName','Length','LastWriteTime') -PassThru | 
        Where-Object {$_.SideIndicator -ne "=="} | 
        Select FullName,ShortName,SideIndicator | 
        Sort-Object -Property @{Expression="SideIndicator";Descending = $True},@{Expression="ShortName";Descending=$False} | 
        ForEach-Object {
            Write-EZLog -Category INF -Message "Comparing $($_.ShortName)" -ToScreen:$ToScreen
            #$BetterPath = Resolve-Path -Path $_.FullName
            if ($_.SideIndicator -eq "=>") {
                $Msg = "Exists in `$target, but not in `$source: $($_.ShortName)"
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                $TargetFile = Join-Path -Path $TargetPath -ChildPath $_.ShortName
                $Msg = "Removing $TargetFile"
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                Remove-Item -Path "$TargetFile" -Force
            }
            if ($_.SideIndicator -eq "<=") {
                $Msg = "Exists in `$source, but not in `$target: $($_.ShortName)"
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                $TargetFile = Join-Path -Path $TargetPath -ChildPath $_.ShortName
                $TargetPathParent = Split-Path -Path $TargetFile -Parent
                Write-Verbose "`$TargetFile is $TargetFile"
                Write-Verbose "`$TargetPathParent is $TargetPathParent"
                $Msg = "Checking if target folder already exists..."
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                if (Test-Path -Path $TargetPathParent -PathType Container) {
                    $Msg = "TargetPathParent already exists..."
                    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                    ###Write-Verbose "$Msg"
                } else {
                    $Msg = "TargetPathParent DOES NOT exist..."
                    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                    ###Write-Verbose "$Msg"
                    $Msg = "Attempting to create TargetPathParent $TargetPathParent"
                    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                    ###Write-Verbose "$Msg"
                    try {New-Item -Path $TargetPathParent -ItemType Directory -ErrorAction SilentlyContinue | Out-Null}
                    catch {}
                }
                $SourceFile = Join-Path -Path $SourcePath -ChildPath $_.ShortName
                $Msg = "Copying $SourceFile to $TargetPathParent"
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                Copy-Item -Path $SourceFile -Destination $TargetPathParent -Force
            } #if SideIndicator -eq "<="
        } #foreach-object
        return $true
    } #try
    catch {
        $ErrorMsg = "Something went wrong in the File Compare-Object pipeline..."
        Write-Error -Message $ErrorMsg -Category InvalidOperation
        Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
        ###Write-Verbose "$ErrorMsg"
        return $false
    } #catch
} #function Mirror-FileItems

Function TheLastThingsToDo {
    #Remove the PSDrive
    $Msg = "Removing PSDrive"
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    try {
        if (Test-Path target:\) {
            Remove-PSDrive -Name target -Force
        } else {
            $Msg = "Looks like target PSDrive not present. Oh well..."
            Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
            ###Write-Verbose "$Msg"
        }
    }
    catch {
        $ErrorMsg = "Unable to remove PSDrive target..."
        Write-Error -Message $ErrorMsg -Category InvalidOperation
        Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
        ###Write-Verbose "$ErrorMsg"
    }

    Write-EZLog -Footer -ToScreen:$ToScreen
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        try {
            Invoke-EZLogRotation -Path $LogFileParentPath -Filter "*$ThisScriptBaseName.log" -Interval Monthly
        }
        catch { }
    }
    Set-Location -Path $originalLocation
}

Write-Verbose "Exiting Functions"
#endregion Functions

#-----------------------------------------------------------[Execution]------------------------------------------------------------
#region Execution
$PSDefaultParameterValues = @{ 	'Write-EZLog:LogFile' = $LogFile ;
                                'Write-EZLog:Delimiter' = ';'
							}

Write-EZLog -Header -ToScreen:$ToScreen
Write-EZLog -Category INF -Message "Beginning script $ThisScriptName" -ToScreen:$ToScreen

#Validate Source Path
$Msg = "Validating Source Path $SourcePath"
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"
if (Test-Path $SourcePath) {
    $SourcePath = $SourcePath.TrimEnd("\")
    Write-EZLog -Category INF -Message "Source path $Path is valid." -ToScreen:$ToScreen
} else {
    $ErrorMsg = "Source Path $SourcePath is not valid. Process failed."
    Write-Error -Message $ErrorMsg -Category InvalidOperation
    Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
    ###Write-Verbose "$ErrorMsg"
    TheLastThingsToDo
    Exit
}

#Validate Credentials path, if supplied.
$Msg = "Checking for supplied credentials"
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"
if (($PSBoundParameters.ContainsKey('CredsPath')) -and (-not ($null -eq $CredsPath))) {
    if (Test-Path $CredsPath) {
        Write-EZLog -Category INF -Message "Credentials path $CredsPath is valid." -ToScreen:$ToScreen
        Write-EZLog -Category INF -Message "Importing credentials from $CredsPath." -ToScreen:$ToScreen
        try {
            $Credential = Import-Clixml -Path $CredsPath
        }
        catch {
            $ErrorMsg = "Unable to import credentials. Process failed."
            Write-Error -Message $ErrorMsg -Category ObjectNotFound
            Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
            ###Write-Verbose "$ErrorMsg"
            TheLastThingsToDo
            Exit
        }
    } else {
        $ErrorMsg = "Credentials path is not valid. Process failed."
        Write-Error -Message $ErrorMsg -Category ObjectNotFound
        Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
        ###Write-Verbose "$ErrorMsg"
        TheLastThingsToDo
        Exit
    }
} else {
    Write-EZLog -Category INF -Message "Credentials not supplied." -ToScreen:$ToScreen
}

if (Test-Path target:\) {
    $Msg = "Removing PSDrive 'target'"
    Write-EZLog -Category INF -Message $Msg -ToScreen:$ToScreen
    ###Write-Verbose $Msg
    Remove-PSDrive -Name target -Force
}

#Creating remote drive
$Msg = "Creating remote drive"
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"
$TargetPath = $TargetPath.TrimEnd("\")
$CreateRemoteDriveResult = Create-RemoteDrive $TargetPath

if (Test-Path target:\) {
    $Msg = "Main Script: Creating remote drive 'target' was successful."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
} else {
    $Msg = "Main Script: Creating remote drive 'target'did not work. Ending script."
    Write-EZLog -Category ERR -Message "$Msg" -ToScreen
    ###Write-Verbose "$Msg"
    Write-Host "Didn't make it to this scope"
    TheLastThingsToDo
    Exit
}

#Getting Source and Target file objects
$Msg = "Getting Source and Target file and folder objects"
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"
try {
    $Msg = "Getting Source files and folders from $SourcePath..."
    $ErrorMsg = "Error $Msg"
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    $sourceItems = Get-ChildItem -Path "$SourcePath" -Recurse -Depth 20 | 
                   Select PSIsContainer,FullName,Name,Length,LastWriteTime,Directory,@{Name='ShortName';Expression={$_.FullName.Replace($SourcePath,'')}} 
    $Msg = "Getting Target files and folders from $TargetPath..."
    $ErrorMsg = "Error $Msg"
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    $targetItems = Get-ChildItem -Path target:\ -Recurse -Depth 20 | 
                   Select PSIsContainer,FullName,Name,Length,LastWriteTime,Directory,@{Name='ShortName';Expression={$_.FullName.Replace($TargetPath,'')}} 
}
catch {
    ###$ErrorMsg is defined in the try block for this one...
    Write-Error -Message $ErrorMsg -Category InvalidOperation
    Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
    ###Write-Verbose "$ErrorMsg"
    TheLastThingsToDo
    Exit
}

#Compare Files and Mirror as necessary
$Msg = "Comparing Files and Mirroring..."
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"
$sourceFiles = $sourceItems | Where-Object {$_.PsIsContainer -ne $true }
$targetFiles = $targetItems | Where-Object {$_.PsIsContainer -ne $true }

<#
Scenario #   $sourceFiles     $targetFiles     Action
----------   ------------     ------------     --------------------
1            Not $null        Not $null        call function Mirror-FileItem
2            Not $null        Is $null         call Copy-Item $SourcePath\* $TargetPath
3            Is $null         Not $null        Remove All TargetFiles **DANGER
4            Is $null         Is $null         Nothing to do - TheLastThingsToDo;Exit;

#>

#Scenario #1
if (($null -ne $sourceFiles) -and ($null -ne $targetFiles)) {
    $Msg = "Mirroring files from source to target..."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    $Results = Mirror-FileItems -SourceFiles $sourceFiles -TargetFiles $targetFiles
    if (-not $Results) {
        TheLastThingsToDo
        Exit
    }
}

#Scenario #2
if (($null -ne $sourceFiles) -and ($null -eq $targetFiles)) {
    $Msg = "Determined no files yet in target. Copying all files from source to target..."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    Copy-Item -Path $SourcePath\* -Destination $TargetPath -Recurse
}

#Scenario #3
if (($null -eq $sourceFiles) -and ($null -ne $targetFiles)) {
    if ($Force) {
        $Msg = "-Force parameter is in effect..."
        Write-EZLog -Category WAR -Message "$Msg" -ToScreen:$ToScreen
        ###Write-Verbose "$Msg"
        $Msg = "Determined files are in target, but not in source. Removing all files in target..."
        Write-EZLog -Category WAR -Message "$Msg" -ToScreen:$ToScreen
        ###Write-Verbose "$Msg"
        Remove-Item -Path $TargetPath -Filter * -Recurse -Force
        TheLastThingsToDo
        Exit
    } else {
        $Msg = "This action would remove all files and folders in the target."
        Write-EZLog -Category WAR -Message "$Msg" -ToScreen
        ###Write-Verbose "$Msg"
        ###Write-Warning -Message $Msg
        $Msg = "If this is the intent, use the -Force parameter and call the script again."
        Write-EZLog -Category WAR -Message "$Msg" -ToScreen
        ###Write-Verbose "$Msg"
        ###Write-Warning -Message $Msg
    }
}

#Scenario #4
if (($null -eq $sourceFiles) -and ($null -eq $targetFiles)) {
    $Msg = "Neither Source nor Target has files, nothing to do..."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    TheLastThingsToDo
    Exit
}

<#
Before we sync up folders, we need to test for the condition where the target folder
didn't already exist or was empty. If the target folder did not already exist or was empty
when we started, then everything that needed to be done with folders was already done
in the preceeding code. Therefore, we're done. Otherwise, continue on...
#>
if ($null -eq $targetFiles) {
    $Msg = "Folder Sync not needed. Successfully completed all steps, we're done..."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    TheLastThingsToDo
    Exit
}

#Getting Source and Target folder objects
$Msg = "Getting Source and Target folder objects"
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"
$sourceFolders = $sourceItems | Where-Object {$_.PSIsContainer -eq $true }
$targetFolders = $targetItems | Where-Object {$_.PSIsContainer -eq $true }

#####################################################################
<#
LEFT OFF HERE....

TO DO:
Need to test for following FOLDER scenarios:
If $sourceFolders is $null, but $targetFolders is not null
If $sourceFolders is not $null, but $targetFolder is null

In otherwords, if either $sourceFolders or $targetFolders is $null,
then Compare-Object will fail. So you need to figure out what to do.

Scenario #   $sourceFolders  $targetFolders    Action
----------   ------------     ------------     --------------------
1            Not $null        Not $null        copy empty folders from source to target;remove extra folders from target.
2            Not $null        Is $null         copy empty folders from source to target.
3            Is $null         Not $null        Remove All Folders from target
4            Is $null         Is $null         Nothing to do - TheLastThingsToDo;Exit;

#>
#####################################################################

<#
 This next section of code needs a bit of explanation.
 There could be circumstances where there are extra folders on the target that no longer exist
 in the source. The first compare-object below handles that situation. "=>" indicates an object
 was found in the DifferenceObject, but not in the ReferenceObject (source). Thus, we need to
 remove that path from the target if it doesn't exist in the source.

 The second compare-object below handles that situation when there could be empty folders in the source,
 but missing in the destination. By default, the previous code above handles Files only. In the above code, if
 a file is new and is in a new folder, then the folder gets created when the file is copied from source 
 to target. But that doesn't happen if the folder is empty. "<=" indicates an object was found in the 
 ReferenceObject (source), but not in the DifferenceObject (target). Therefore, if a folder was found in the 
 source but not in the target, the second compare-object handles that situation.

 But you may ask, why did you split that into two Compare-Objects when you could have just done it in one?
 That's partially true. However, it was split into two Compare-Objects for two reasons.
 
 Reason #1: In order to prevent or to hide error messages with either Remove-Item or New-Item, the sort of the 
 paths is important. With "=>", the path name needs to be sorted in Descending Order. That will allow Remove-Item
 to remove paths from the deepest level folder to up the chain.
 With "<=", the path name needs to be sorted in ascending order. That will allow New-Item to create folders from
 the highest level folder to down the chain. Thus, this is why I chose to break the logic in two parts.
 
 Reason #2: For a future enhancement, creating empty folders on the target folder will be an option switch.
 By breaking the Compare-Objects to two parts, it will be easier to implement a switch that can execute or bypass
 the section of code that creates the empty folders on the target path.
#>
#Scenario #1
if (($null -ne $sourceFolders) -and ($null -ne $targetFolders)) {
    #Compare Folders and Mirror as necessary
    $Msg = "Comparing Folders and syncing extra or empty folders..."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    try {
        $Msg = "Comparing Folders and removing target folders that don't exist in source..."
        Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
        ###Write-Verbose "$Msg"
        Compare-Object -ReferenceObject $sourceFolders -DifferenceObject $targetFolders -Property ('ShortName') -PassThru | 
        Where-Object {$_.SideIndicator -eq  "=>"} | 
        Sort-Object -Property @{Expression="SideIndicator";Descending = $True},@{Expression="ShortName";Descending=$True} | 
        ForEach-Object {
            $MissingFolder = $_.FullName
            $Msg = "Removing $MissingFolder on Target"
            Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
            ###Write-Verbose "$Msg"
            Remove-Item -Path $MissingFolder -Force
        } #ForEach-Object

        $Msg = "Comparing Folders and creating target folders that exist in source but not the target..."
        Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
        ###Write-Verbose "$Msg"
        Compare-Object -ReferenceObject $sourceFolders -DifferenceObject $targetFolders -Property ('ShortName') -PassThru | 
        Where-Object {$_.SideIndicator -eq  "<="} | 
        Sort-Object -Property @{Expression="SideIndicator";Descending = $True},@{Expression="ShortName";Descending=$False} | 
        ForEach-Object {
            $MissingFolder = $_.FullName.Replace($SourcePath,$TargetPath)
            if (!(Test-Path -Path $MissingFolder)) {
                $Msg = "Creating $MissingFolder on Target"
                Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                ###Write-Verbose "$Msg"
                try {New-Item -Path $MissingFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null}
                catch {
                    $Msg = "Nevermind, $MissingFolder must have already been created."
                    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
                    ###Write-Verbose "$Msg"
                }
            }
        } #ForEach-Object
    } #try
    catch {
        $ErrorMsg = "Something went wrong in the Folder Compare-Object pipeline..."
        Write-Error -Message $ErrorMsg -Category InvalidOperation
        Write-EZLog -Category ERR -Message "$ErrorMsg" -ToScreen
        ###Write-Verbose "$ErrorMsg"
        TheLastThingsToDo
        Exit
    } #catch

} #if $null -ne $sourceFolders and $targetFolders

#Scenario #2
###Nothing to do, should have happened with File copy section above.

#Scenario #3
###Remove all folders on Target.
####Nothing to do, because should have happened with File copy, RIGHT?
#####CHECK THIS WITH ACTUAL TESTING....

#Scenario #4
#If there are no folders in either source or target, no need to go on.
if (($null -eq $sourceFolders) -and ($null -eq $targetFolders)) {
    $Msg = "No folders in either source or target. Successfully completed all steps, we're done..."
    Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
    ###Write-Verbose "$Msg"
    TheLastThingsToDo
    Exit
}

$Msg = "Successfully completed all steps..."
Write-EZLog -Category INF -Message "$Msg" -ToScreen:$ToScreen
###Write-Verbose "$Msg"

TheLastThingsToDo
#endregion Execution
