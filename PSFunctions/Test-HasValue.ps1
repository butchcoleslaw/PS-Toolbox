<#
Function Test-HasValue
This function will return true if a value is present,
and false if a value is missing, empty, null.
Some built-in powershell functions, like Split-Path, will return an error
when the -Path parameter is empty. Since the -ErrorAction SilentlyContinue does not
appear to work with the Split-Path function when the Path value is empty, this function
can be used ahead of time to see if the parameter value is not empty or null.
#>
Function Test-HasValue {
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param(
        # Output file you wish to direct information to
        [Parameter(Mandatory=$false)]
        [string]$Arg1
    )
    if ([string]::IsNullOrWhiteSpace($Arg1)) {
        Return $false
    } else {
        Return $true
    }
}
