<#
.SYNOPSIS
    Create a new 7-Zip self extracting archive
.DESCRIPTION
    Create self-extracting archives using 7-Zip
.EXAMPLE
    New-7zsfx app-sfx app.exe,app.exe.config app.exe

    Simply create a self-extracting exe from an executable file app.exe
    with its configuration file app.exe.config:
#>
Function New-7zSfx {
    [CmdletBinding()]
    Param(
        # The name of the exe-file to produce, without extension
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,

        # The files to include in the archive
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)]
        [string[]]$Include,

        # The command to run when the sfx archive is started
        [Parameter(Mandatory=$true, Position=2)]
        [string]$CommandToRun,

        # Title for messages
        [Parameter(Mandatory=$false)]
        [string]$Title,

        # Begin Prompt message
        [Parameter(Mandatory=$false)]
        [string]$BeginPrompt,

        # Title of extraction dialog
        [Parameter(Mandatory=$false)]
        [string]$ExtractTitle,

        # Text in dialog
        [Parameter(Mandatory=$false)]
        [string]$ExtractDialogText,

        # Button text of cancel button
        [Parameter(Mandatory=$false)]
        [string]$ExtractCancelText,

        # A list of additional options, of the form "key=value"
        [Parameter(Mandatory=$false)]
        [string[]]$ConfigOptions,

        # Include subdirectories
        [switch]$Recurse,

        # Additional switches to pass to 7z when creating the archive
        [string]$Switches = ''
    )

    Begin {
        # Get the base name of the specified path in Name
        if (-not [IO.Path]::IsPathRooted($Path)) {
            $Path = Join-Path "." $Path
        }
        # The join the directory name with the file name exluding the extension
        [string]$Name = Join-Path ([IO.Path]::GetDirectoryName($Path)) ([IO.Path]::GetFileNameWithoutExtension($Path))
        
        [string]$tmpfile = "$Name.sfx.tmp"
        [string]$exefile = "$Name.exe"

        if (Test-Path -PathType Leaf "$exefile") {
            Remove-Item "$exefile" -Force
        }

        $filesToInclude = @()
    }

    Process {
        $filesToInclude += $Include
    }

    End {
        # Escape a variable for the config file
        Function Escape([string]$t) {
            # Prefix \ and " with \, replace CRLF with \n and TAB with \t
            Return $t.Replace('\', '\\').Replace('"', '\"').Replace("`r`n", '\n').Replace("`t", '\t')
        }

        [string[]]$output = New-7zArchive -Path $tmpfile -Include $filesToInclude -Exclude @() -Type 7z -Recurse:$Recurse -Switches $Switches

        # Copy sfx + archive + config to exe

    <#
        http://www.7zsfx.info/en/

        Title - title for messages
        BeginPrompt - Begin Prompt message
        Progress - Value can be "yes" or "no". Default value is "yes".
        RunProgram - Command for executing. Default value is "setup.exe". Substring %%T will be replaced with path to temporary folder, where files were extracted
        Directory - Directory prefix for "RunProgram". Default value is ".\\"
        ExecuteFile - Name of file for executing
        ExecuteParameters - Parameters for "ExecuteFile"
        ExtractTitle - title of extraction dialog
        ExtractDialogText - text in dialog
        ExtractCancelText - button text of cancel button
    #>

        [string]$cfg = @"
;!@Install@!UTF-8!
Title="$Title"
RunProgram="$(Escape($CommandToRun))"

"@

        if ($BeginPrompt -ne "") {
            $cfg += "BeginPrompt=`"$(Escape($BeginPrompt))`"`r`n"
        }
        if ($ExtractTitle -ne "") {
            $cfg += "ExtractTitle=`"$(Escape($ExtractTitle))`"`r`n"
        }
        if ($ExtractDialogText -ne "") {
            $cfg += "ExtractDialogText=`"$(Escape($ExtractDialogText))`"`r`n"
        }
        if ($ExtractCancelText -ne "") {
            $cfg += "ExtractCancelText=`"$(Escape($ExtractCancelText))`"`r`n"
        }

        if ($ConfigOptions -ne $null) {
            $ConfigOptions | ForEach-Object {
                [string[]]$parts = $_.Split('=')
                if ($parts.Length -lt 2) {
                    throw "Invalid configuration option '$($_)': missing '='"
                } else {
                    $cfg += "$($parts[0])=`"$(Escape($parts[1]))`"`r`n"
                }
            }
        }

        $cfg += ";!@InstallEnd@!`r`n"

        Write-Verbose "Creating sfx `"$exefile`"..."
        Write-Debug $cfg

        [string]$cfgfile = "$Name.sfx.cfg"

        Set-Content "$cfgfile" -Value $cfg
        Get-Content "$7Z_SFX","$cfgfile","$tmpfile" -Encoding Byte -Raw | Set-Content "$exefile" -Encoding Byte

        Remove-Item "$tmpfile"
        Remove-Item "$cfgfile"
    }
}
