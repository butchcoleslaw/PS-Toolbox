<# ConvertTo-7ZipPath
  In order for 7-zip to store the path in the compressed file, two requirements must be met.
  First, you must change to the root folder of the current drive,
  And Second, you must remove the drive letter and leading slash from the path.
  This means that a path that looks like this:  "C:\Util\Logs\*.log"
  Must be converted to look like this:  "Util\Logs\*.log"
#>
Function ConvertTo-7ZipPath {
    [CmdletBinding()]
    [OutputType([String[]])]
    Param(
        # A list of file names or patterns to include
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]]$ListOfPaths
    )
    $ListOfPaths = $ListOfPaths | ForEach-Object {
        [int]$startPos = 3
        [int]$varLength = $_.Length
        #Modify the current item
        $_ = $_.Substring($startPos,$varLength-$startPos)
        #Drop the modified item back into the pipeline
        $_
        Write-Verbose "New 7zip Path is $_"
    }

    return $ListOfPaths
}

