<# Get-FileExt
   Accept a string, assume it is a file name.
   Doesn't matter if the file exists or not.
   Return everything after the last period as the extension.
   If no period or no extension, then Null or empty string will be returned.
   This is used for Add or Update. If no archive type is specified, check the archive's extension.
   If the extension is "zip", pass "-tzip" as part of the -Switches. Otherwise assume 7z archive type.
#>
Function Get-FileExt {
    [CmdletBinding()]
    [OutputType([String])]
    Param(
        # File name for which you want the extension
        [Parameter(Mandatory=$true)]
        [string]$FileName
    )
    $Split = $FileName.Trim().TrimStart(".").TrimEnd(".").Split(".")
    $SplitCount =$Split.Count - 1
    Write-Debug "SplitCount is $SplitCount"
    if ($SplitCount -le 0) {
        Return $null
    } else {
        Return $Split[$SplitCount]
    }
}
