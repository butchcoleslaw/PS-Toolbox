<#
.SYNOPSIS
    Create a new 7-Zip archive
.DESCRIPTION
    Use this cmdlet to create 7-Zip archives. Possible types are 7z (default) and zip.
    The archive file is overwritten if it exists!
.EXAMPLE
    New-7zArchive new-archive *.txt

    Creates a new 7-zip-archive named 'new-archive.7z' containing all files with a .txt extension
    in the current directory
.EXAMPLE
    New-7zArchive new-archive *.txt -Type zip

    Creates a new zip-archive named 'new-archive.zip' containing all files with a .txt extension
    in the current directory
.EXAMPLE
    New-7zArchive new-archive *.jpg,*.gif,*.png,*.bmp -Recurse -Exclude tmp/

    Creates a new 7-zip archive named 'new-archive.7z' containing all files with an extension
    of jpg, gif, png or bmp in the current directory and all directories below it

    All files in the folder tmp are excluded, i.e. not included in the archive.
#>
Function New-7zArchive {
    [CmdletBinding()]
    Param(
        # The path of the archive to create
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # A list of file names or patterns to include
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]]$Include,

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @(),

        # The type of archive to create
        [ValidateSet("7z", "zip")]
        [string]$Type = "7z",

        # Apply include patterns recursively
        [switch]$Recurse,

        # Additional switches for 7z
        [string]$Switches = ""
    )

    Begin {
        # Make sure the archive is deleted before it is created
        if (Test-Path -PathType Leaf $Path) {
            Remove-Item $Path | Out-Null
        }
        $filesToProcess = @()
    }
    Process {
        $filesToProcess += $Include
    }
    End {
        $Switches = "$Switches -t$Type"
        [string[]]$result = Invoke-7zOperation -Operation Add -Path $Path -Include $filesToProcess -Exclude $Exclude -Recurse:$Recurse -Switches $Switches
    }
}
