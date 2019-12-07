<#
.SYNOPSIS
    Update files in a 7-Zip archive
.DESCRIPTION
    Use this cmdlet to update files to an existing 7-Zip archive. If the archive does not
    exists, it is created
#>
Function Update-7zArchive {
    [CmdletBinding()]
    Param(
        # The path of the archive to update
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # A list of file names or patterns to include
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]]$Include,

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @(),

        # Apply include patterns recursively
        [switch]$Recurse,

        # Additional switches for 7z
        [string]$Switches = ""
    )

    Begin {
        $filesToProcess = @()
        if ($ZipType -eq "zip") {
            $Switches = "$Switches -tzip"
        }
    }
    Process {
        $filesToProcess += $Include
    }
    End {
        [string[]]$result = Invoke-7zOperation -Operation Update -Path $Path -Include $filesToProcess -Exclude $Exclude -Recurse:$Recurse -Switches $Switches
    }
}
