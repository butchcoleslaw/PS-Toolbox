<#
.SYNOPSIS
    List the files in a 7-Zip archive.
.DESCRIPTION
    Use this cmdlet to examine the contents of 7-Zip archives.
    Output is a list of PSCustomObjects with properties [string]Mode, [DateTime]DateTime, [int]Length, [int]Compressed and [string]Name
.EXAMPLE
    Get-7zArchive c:\temp\test.7z

    List the contents of the archive "c:\temp\test.7z"
#>
Function Get-7zArchive {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    Param(
        # The name of the archive to list
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # Additional switches
        [Parameter(Mandatory=$false)]
        [string]$Switches = "",

        # Specific Property you wish to extract
        [Parameter(Mandatory=$false)]
        [ValidateSet("All", "Name", "Mode", "DateTime", "Length", "CompressedLength")]
        [string]$Property = "All",

        # Output file you wish to direct information to
        [Parameter(Mandatory=$false)]
        [string]$OutputFile = ""
    )

    # This section of code is used to validate if a valid output file value was specified.
    [boolean]$IsValidPath = $false
    if (Test-HasValue $OutputFile) {
        $OutputFileParent = Split-Path -Path $OutputFile -Parent
        if (Test-HasValue $OutputFileParent) {
            if (Test-Path -Path $OutputFileParent -PathType Container) {
                $IsValidPath = $true
                if (Test-Path -Path $OutputFile) {
                    Remove-Item -Path $OutputFile -Force
                }
                Set-Content -Path $OutputFile -Encoding Ascii -Force -Value $null
            }
        }
    }

    [string[]]$result = Invoke-7zOperation -Operation List -Path $Path -Include @() -Exclude @() -Recurse:$false -Switches $Switches -CheckOK:$false

    [bool]$separatorFound = $false
    [int]$filecount = 0

    $result | ForEach-Object {
        if ($_.StartsWith("------------------- ----- ------------ ------------")) {
            if ($separatorFound) {
                # Second separator! We're done
                break
            }
            $separatorFound = -not $separatorFound
        } else {
            if ($separatorFound) {
                # 012345678901234567890123456789012345678901234567890123456789012345678901234567890
                # x-----------------x x---x x----------x x----------x  x--------------------
                # 2015-12-20 14:25:18 ....A        18144         2107  XMLClassGenerator.ini
                [string]$mode = $_.Substring(20, 5)
                [DateTime]$datetime = [DateTime]::ParseExact($_.Substring(0, 19), "yyyy'-'MM'-'dd HH':'mm':'ss", [CultureInfo]::InvariantCulture)
                [int]$length = [int]"0$($_.Substring(26, 12).Trim())"
                [int]$compressedlength = [int]"0$($_.Substring(39, 12).Trim())"
                [string]$name = $_.Substring(53).TrimEnd()

                switch ($Property) {
                    "name" { 
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $name -Encoding Ascii
                        } else {
                            Write-Host $name
                        }
                    }
                    "mode" {
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $mode -Encoding Ascii
                        } else {
                            Write-Host $name
                        }
                    }
                    "datetime" {
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $datetime -Encoding Ascii
                        } else {
                            Write-Host $name
                        }
                    }
                    "length" {
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $length -Encoding Ascii
                        } else {
                            Write-Host $name
                        }
                    }
                    "compressedlength" {
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $compressedlength -Encoding Ascii
                        } else {
                            Write-Host $name
                        }
                    }
                    "all" {
                        $allvalues = "Mode=$mode,DateTime=$datetime,Length=$length,Compressed=$compressedlength,Name=$name"
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $allvalues
                        } else {
                            Write-Host $allvalues
                        }
                    }
                    default {
                        $allvalues = "Mode=$mode,DateTime=$datetime,Length=$length,Compressed=$compressedlength,Name=$name"
                        if ($IsValidPath) {
                            Add-Content -Path $OutputFile -Value $allvalues
                        } else {
                            Write-Host $allvalues
                        }
                    }
                }

                # Write a PSCustomObject with properties to output
                <#Write-Output ([PSCustomObject] @{
                    Mode = $mode
                    DateTime = $datetime
                    Length = $length
                    Compressed = $compressedlength
                    Name = $name

                }) #>
                $filecount++
            }
        }
    }
}
