#region Comments
<#
    Powershell Module 7-Zip - 7-Zip commands for PowerShell

    The functions in this module call 7z.exe, the standAlone version of 7-zip to perform various tasks on 7-zip archives.
    Place anywhere, together with 7z.exe and 7z.sfx. 7z.exe is required for all operations; 7z.sfx for creating self
    extracting archives.

    http://www.7-zip.org

    Import-Module [Your path\]7-Zip

    Brought to you by MOBZystems, Home of Tools - http://www.mobzystems.com/

    License: use at will!

----------------------------------------------------------------------------------------------------------------------------------    
Additional Changes and Enhancements by Listo Systems,LLC
Ken Friddle
August 2019
----------------------------------------------------------------------------------------------------------------------------------    
    TODO:
8-27-2019
Add a Parameter that will specify the exact location of 7z.exe, like this -7zLocation 'C:\Program Files\7-zip'

Add a Parameter Switch that will initiate a search for drive and location in which 7z.exe can be found, like this: -SearchFor7Zip
Places to search:
This script's path
Iterate across all available drives and search in the drive:\Program Files\7-Zip until it is found.

----------------------------------------------------------------------------------------------------------------------------------
Maintenance
----------------------------------------------------------------------------------------------------------------------------------
20190903 - Added -Help parameter to exhibit Help text by Operation

----------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------
Calling Parameters
---------------------------------------------------------
[string]$ZipOperation = Add,Update,New,List,Extract,Test
[string]$ZipFilePath
[string]$Switches
[string]$TargetFilePath
[string[]]$Include (comma separated list; do not surround list with quotes)
[string[]]$Exclude (comma separated list; do not surround list with quotes)
OBSOLETE-NOT USED[string]$ZipType = 7z,zip
[string]$ZipListProperty = All,Name,Mode,DateTime,Length,CompressedLength
[string]$ZipListOutputFile
[string]$ZipExpandDestination
[switch]$ZipExpandWithFullPath
[switch]$Recurse
[switch]$Force
[switch]$StorePath
[string]$Help = All,Add,Update,New,List,Extract,Test

----------------------------------------------------------------------------------------------------------------------------------    
Parameters by Operation
---------------------------------------------------------
"Operation" is any value in the $ZipOperation parameter.
For ALL operations:
	$ZipOperation If Missing, defaults to Test.
	$ZipFilePath  REQUIRED - File extension should be .zip or .7z.
	              If not .zip or .7z, then Path is modified to add .zip extension.
---------------------------------------------------------
#>
#endregion Comments

#region Script Parameters
[CmdletBinding()]
Param(
        # The operation to perform
        [Parameter(Mandatory=$false)]
        [ValidateSet("Add", "Update", "New", "List", "Extract", "Test")]
        [string]$ZipOperation,

        # The path of the archive
        [Parameter(Mandatory=$false)]
        [string]$ZipFilePath,

        # Additional Switches for the 7-Zip command
        [Parameter(Mandatory=$false)]
        [string]$Switches = "",

        # The path of the files to archive
        [Parameter(Mandatory=$false)]
        [string]$TargetFilePath,

        # A list of file names or patterns to include
        # When you provide a list of filespecs to include, separate with a comma, do not surround with quotes.
        [Parameter(Mandatory=$false)]
        [string[]]$Include = @("*"),

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @(),

        # The property you want from the 7-Zip List command
        [Parameter(Mandatory=$false)]
        [ValidateSet("All", "Name", "Mode", "DateTime", "Length", "CompressedLength")]
        [string]$ZipListProperty,

        # The path output from the 7-Zip List command
        [Parameter(Mandatory=$false)]
        [string]$ZipListOutputFile,

        # The path of the extracted/expanded artifacts
        [Parameter(Mandatory=$false)]
        [string]$ZipExpandDestination,

        # Expand to stored folders
        [Parameter(Mandatory=$false)]
        [switch]$ZipExpandWithFullPath,

        # Apply include patterns recursively
        [switch]$Recurse,

        # Force overwriting existing files
        [switch]$Force,

        # Store the file path in the archive
        [switch]$StorePath,

        # Invoke Help for the command
        [Parameter(Mandatory=$false)]
        [ValidateSet("All", "Add", "Update", "New", "List", "Extract", "Test")]
        [string]$Help
)
#endregion Script Parameters

# Be strict
Set-StrictMode -Version Latest

#region Define 7zip Location
# Module variables
# [string]$SCRIPT_DIRECTORY = Split-Path ($MyInvocation.PSCommandPath) -Parent
[string]$SCRIPT_DIRECTORY = $PSCommandPath
[string]$7Z_DIRECTORY = "$PSScriptRoot\7-Zip"
Write-Verbose "Script Directory is $SCRIPT_DIRECTORY"

[string]$7Z_SFX = Join-Path $7Z_DIRECTORY "7z.sfx"
[string]$7Z_EXE = Join-Path $7Z_DIRECTORY "7z.exe"
Write-Verbose "Path to 7-Zip is $7Z_EXE"

# Sanity checks
if (!(Test-Path -PathType Leaf $7Z_EXE)) {
    Write-Warning "Cannot find 7z.exe in `"$7Z_DIRECTORY`". This file is required for all operations in this module"
}
if (!(Test-Path -PathType Leaf $7Z_SFX)) {
    Write-Warning "Cannot find 7z.sfx in `"$7Z_DIRECTORY`". This file is required for New-7zSfx"
}
#endregion Define 7zip Location

#region Dot Source Functions
<# Test if required functions are present.
   Dot sourcing of functions done here.
 #>
$FunctionPath = $PSScriptRoot + "\PSFunctions"
$AllFunctionsFound = $true
$MsgFunctionNotFound = "The following functions were not found: `n"
$CurrentFunction = "Test-HasValue.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Get-FileExt.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "ConvertTo-7ZipPath.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Invoke-7zOperation.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "New-7zArchive.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Add-7zArchive.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Update-7zArchive.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Expand-7zArchive.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Get-7zArchive.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Test-7zArchive.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "New-7zSfx.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

$CurrentFunction = "Show-7zHelp.ps1"
if (!(Test-Path -Path "$FunctionPath\$CurrentFunction")) {
    $AllFunctionsFound = $false
    $MsgFunctionNotFound += "- $CurrentFunction"
} else {
    . "$FunctionPath\$CurrentFunction"
}

# If any of the dot sourced functions are missing, write out error message and exit
if (!($AllFunctionsFound)) {
    Write-Host $MsgFunctionNotFound -ForegroundColor Red -BackgroundColor White
    Exit
}
#endregion Dot Source Functions

##Export-ModuleMember -Function *-7z*

#region Process Help
#Invoke Help for the command, then exit.
#When Help is invoked, no other parameters are validated.
if ($PSBoundParameters.ContainsKey('Help')) {
    switch ($Help) {
        "Add"     { Show-7zHelp -Operation Add     }
        "Update"  { Show-7zHelp -Operation Update  }
        "New"     { Show-7zHelp -Operation New     }
        "List"    { Show-7zHelp -Operation List    }
        "Extract" { Show-7zHelp -Operation Extract }
        "Test"    { Show-7zHelp -Operation Test    }
        default { 
            Show-7zHelp -Operation Add
            Show-7zHelp -Operation Update
            Show-7zHelp -Operation New
            Show-7zHelp -Operation List
            Show-7zHelp -Operation Extract
            Show-7zHelp -Operation Test
        }
    }
    Exit
}
#endregion Process Help

#region Validations and Defaults
#Here you need to set defaults if they weren't provided on the command line.
if (!($PSBoundParameters.ContainsKey('ZipListProperty'))) {
    $ZipListProperty = "All"
}

# Check that there is a Zip file listed
if (!($PSBoundParameters.ContainsKey('ZipFilePath'))) {
    Write-Error -Message "ZipFilePath parameter missing." -Category InvalidArgument
    Write-Host "Please specify a Zip file and path for the -ZipFilePath parameter."
    Exit
} else {
    $ZipFilePath = $ZipFilePath.Trim().TrimEnd(".")
}

#Other Validations
# Validate that the Include list does not have a path in it.
$Include | ForEach-Object {
    if ($_.Contains("\")){
        Write-Error -Message "Invalid Include data found." -Category InvalidData
        Write-Host "Do not include the full or partial path of the include file spec."
        Exit
    }
}
# If a TargetFilePath was given, validate the path.
# If the TargetFilePath is valid, concatenate the path with each item in the $Include list.
if (!([string]::IsNullOrWhiteSpace($TargetFilePath))) {
    if (!(Test-Path -Path $TargetFilePath)) {
        Write-Error -Message "Target File invalid path." -Category ObjectNotFound
        Write-Host "Please correct the TargetFilePath parameter and try again."
        Exit
    } else {
        # For all operations that use the $Include variable, we want to concatentate the path
        # with the file list UNLESS the ZipOperation is Extract. For extraction, we don't need
        # a full path to the files inside the archive.
        if ($ZipOperation -ne "Extract") {
            #Create full paths for the Include list
            #$TargetFilePath = (Resolve-Path -Path $TargetFilePath).Path
            $TargetFilePath = $TargetFilePath.TrimEnd("\")
            $Include = $Include | ForEach-Object {
                # Concatenate the path to the item
                $_ = $TargetFilePath + '\' + $_.Trim()
                # Drop the item back into the pipeline
                $_
                Write-Verbose "The concatenated path is $_"
            } #ForEach
        
        } #if ZipOperation -ne Extract
    } #else Test-Path $TargetFilePath
} #if value is given for TargetFilePath

# Validation when the Operation is extract
if ($ZipOperation -eq "Extract") {
    # Make sure the Zip file you want to extract already exists
    if (!(Test-Path -Path $ZipFilePath -PathType Leaf)) {
        Write-Error -Message "Zip file not found." -Category InvalidData
        Write-Host "For an Extract Operation, provide the name of an existing archive file and try again."
        Exit
    }
    # Make sure the Destination Path exists
    if (!(Test-Path -Path $ZipExpandDestination -PathType Container)) {
        Write-Verbose "Expand Destination not found. Creating folder $ZipExpandDestination."
        New-Item -Path $ZipExpandDestination -ItemType Directory | Out-Null
    }
}

# If the Operation is either Add, Update, or New, then check the extension of the ZipFilePath.
# Set the $ZipType based on the value of the file extension.
$OpCollection1 = "Add","Update","New"
$ExtCollection1 = "zip","7z"
if($ZipOperation -in $OpCollection1) {
    Write-Debug "Found the $ZipOperation Operation in the OpCollection"
    $FileExt = Get-FileExt $ZipFilePath
    Write-Debug "FileExt of ZipFilePath is $FileExt"
    if ($FileExt -notin $ExtCollection1) {
        #The file extension of the ZipFilePath is neither 7z nor zip.
        #Therefore we will set it to zip and set the ZipType to zip.
        Write-Debug "The extension is neither Zip nor 7z"
        $ZipFilePath = $ZipFilePath + ".zip"
        $ZipType = "zip"
    } else {
        Write-Debug "The extension is Zip or 7z"
        $ZipType = $FileExt
    }
}
#endregion Validations and Defaults

#region Main Logic
# This is where we process the operation and perform the zip task.
switch ($ZipOperation) {
    "Add"     { Add-7zArchive -Path $ZipFilePath -Include $Include -Exclude $Exclude -Recurse:$Recurse -Switches $Switches }
    "Update"  { Update-7zArchive -Path $ZipFilePath -Include $Include -Exclude $Exclude -Recurse:$Recurse -Switches $Switches}
    "New"     { New-7zArchive -Path $ZipFilePath -Include $Include -Exclude $Exclude -Type $ZipType -Recurse:$Recurse -Switches $Switches}
    "List"    { Get-7zArchive -Path $ZipFilePath -Switches $Switches -Property $ZipListProperty -OutputFile $ZipListOutputFile }
    "Extract" { Expand-7zArchive -Path $ZipFilePath -Destination $ZipExpandDestination -Include $Include -Exclude $Exclude -Recurse:$Recurse -Switches $Switches -Force:$Force -WithFullPath:$ZipExpandWithFullPath }
    "Test"    { Test-7zArchive -Path $ZipFilePath -Switches $Switches -Verbose}
    default   { Test-7zArchive -Path $ZipFilePath -Switches $Switches -Verbose }
}
#endregion Main Logic
