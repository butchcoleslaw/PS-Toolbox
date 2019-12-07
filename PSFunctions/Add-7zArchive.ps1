<#
.SYNOPSIS
    Add files to a 7-Zip archive
.DESCRIPTION
    Use this cmdlet to add files to an existing 7-Zip archive. If the archive does not
    exists, it is created
#>
Function Add-7zArchive {
    [CmdletBinding()]
    Param(
        # The path of the archive to add to
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # A list of file names or patterns to include
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]]$Include,

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @(),

        # The type of archive to create
        # Apply include patterns recursively
        [switch]$Recurse,

        # Additional switches for 7z
        [string]$Switches = ""
    )

    Begin {
        if ($ZipType -eq "zip") {
            $Switches = "$Switches -tzip"
        }
        $filesToProcess = @()
    }
    Process {
        $filesToProcess += $Include
    }
    End {
        [string[]]$result = Invoke-7zOperation -Operation Add -Path $Path -Include $filesToProcess -Exclude $Exclude -Recurse:$Recurse -Switches $Switches
    }
}
