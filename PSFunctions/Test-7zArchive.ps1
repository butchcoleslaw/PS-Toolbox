<#
.SYNOPSIS
    Test a new 7-Zip archive.
.DESCRIPTION
    Use this cmdlet to test 7-Zip archives for errors
.EXAMPLE
    Test-7zArchive c:\temp\test.7z

    Test the archive "c:\temp\test.7z". Throw an error if any errors are found
#>
Function Test-7zArchive {
    [CmdletBinding()]
    Param(
        # The name of the archive to test
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # Additional switches
        [Parameter(Mandatory=$false, Position=1)]
        [String]$Switches = ""
    )

    [string[]]$result = Invoke-7zOperation -Operation Test -Path $Path -Include @() -Exclude @() -Recurse:$false -Switches $Switches -CheckOK:$false

    # Check result
    if ($result.Contains("No files to process")) {
        Write-Verbose "Archive is empty"
        return
    }

    if ($result.Contains("cannot find archive")) {
        throw "Archive `"$Path`" not found"
    }

    if ($result.Contains("Everything is Ok")) {
        Write-Verbose "Archive is OK"
        return
    }

    # In all other cases, we have an error. Write out the results Verbose
    $result | Write-Verbose
    # ... and throw an error
    throw "Testing archive `"$Path`" failed: $result"
}
