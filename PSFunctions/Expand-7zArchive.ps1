<#
.SYNOPSIS
    Extract files fom a 7-Zip archive
.DESCRIPTION
    Use this cmdlet to extract files from an existing 7-Zip archive
.EXAMPLE
    Expand-7zArchive backups.7z 
#>
Function Expand-7zArchive {
    [CmdletBinding()]
    Param(
        # The path of the archive to extract
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # The path to extract files to
        [Parameter(Mandatory=$false, Position=1)]
        [string]$Destination = ".",

        # A list of file names or patterns to include
        [Parameter(Mandatory=$false, ValueFromPipeLine=$true, Position=2)]
        [string[]]$Include = @("*"),

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @(),

        # Apply include patterns recursively
        [switch]$Recurse,

        # Additional switches for 7z
        [string]$Switches = "",

        # Force overwriting existing files
        [switch]$WithFullPath,

        # Force overwriting existing files
        [switch]$Force
    )

    Begin {
        $Switches = $Switches + " `"-o$Destination`""
        if ($Force) {
            $Switches = $Switches + " -aoa" # Overwrite ALL
        } else {
            $Switches = $Switches + " -aos" # SKIP extracting existing files
        }

        $filesToProcess = @()
    }
    Process {
        $filesToProcess += $Include
    }

    End {
        [string[]]$result = Invoke-7zOperation -Operation Extract -Path $Path -Include $filesToProcess -Exclude $Exclude -Recurse:$Recurse -Switches $Switches -WithFullPath:$WithFullPath

        $result | ForEach-Object {
            if ($_.StartsWith("Skipping    ")) {
                Write-Warning $_
            }
        }
    }
}
