<#
    This (internal) function does the hard work: it calls 7z with the appropriate arguments
#>
Function Invoke-7zOperation {
    [CmdletBinding()]
    Param(
        # The operation to perform
        [Parameter(Mandatory=$true)]
        [ValidateSet("Add", "Update", "List", "Extract", "Test")]
        [string]$Operation,

        # The path of the archive
        [Parameter(Mandatory=$true)]
        [string]$Path,

        # A list of file names or patterns to include
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]]$Include,

        # A list of file names or patterns to exclude
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]]$Exclude,

        # Apply include patterns recursively
        [Parameter(Mandatory=$true)]
        [switch]$Recurse,

        # Additional switches for 7z
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Switches,

        # Specify whether or not to extract files with full path
        [Parameter(Mandatory=$false)]
        [switch]$WithFullPath,

        # Throw if the output does not contain "Everything is OK"
        [Parameter(Mandatory=$false)]
        [switch]$CheckOK = $true
    )

    #For Add and Update operations only, we need to tweak the path if StorePath switch is true
    $AddUpdateOpCollection = "Add","Update"
    if($Operation -in $AddUpdateOpCollection) {
        if ($StorePath -eq $true) {
            $currdir = $PWD
            $Include = ConvertTo-7ZipPath $Include
            Write-Debug "Changing Path in order to store the path in the archive."
            (Split-Path -Path $currdir -Qualifier) + "\" | Set-Location
        }
    }
    switch ($Operation) {
    "Add" {
            $7zcmd = "a"
            $verb = "Adding to"
        }
    "Update" {
            $7zcmd = "u"
            $verb = "Updating"
        }
    "Extract" {
            if ($WithFullPath) {
                $7zcmd = "x"
            } else {
                $7zcmd = "e"
            }
            $verb = "Extracting"
        }
    "List" {
            $7zcmd = "l"
            $verb = "Listing"
        }
    "Test" {
            $7zcmd = "t"
            $verb = "Testing"
        }
    }

    # Create a list of quoted file names from the $Include argument
    [string]$files = ""
    $Include | ForEach-Object { $files += " `"$_`"" }
    $files = $files.TrimStart()

    Write-Debug "Files list is $files"

    # Set up switches to use
    $Switches += " -bd -y" # -bd: no percentage indicator, -y: Yes to all prompts
    if ($Recurse) {
        $Switches += " -r" # -r: recurse
    }
    # Add excludes to the switches
    $Exclude | ForEach-Object { $Switches += " `"-x!$_`"" }
    $Switches = $Switches.TrimStart()

    Write-Verbose "$verb archive `"$Path`""
    [string]$cmd = "`"$7Z_EXE`" $7zcmd $Switches `"$Path`" $files"
    Write-Debug $cmd
    Invoke-Expression "&$cmd" -OutVariable output | Write-Verbose

    # If we changed the path previously due to the StorePath switch, now is the time to change it back.
    if($Operation -in $AddUpdateOpCollection) {
        if ($StorePath -eq $true) {
            Set-Location -Path $currdir
            Write-Debug "Location changed back to $currdir"
        }
    }

    # Check result
    if ($CheckOK) {
        if (-not ([string]$output).Contains("Everything is Ok")) {
            throw "$verb archive `"$Path`" failed: $output"
        }
    }

    # No error: return the 7-Zip output
    Write-Output $output
}

