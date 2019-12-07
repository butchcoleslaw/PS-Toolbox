<#
   Help Text for the different Zip Operations.
   This serves two purposes. The first is that the below serves as 
   documentation for the overall script on the different zip operations.
   Second, this serves as the actual output when the -Help parameter is used.
#>
$HelpTextList = @"
For List Operation:
Purpose: To get a listing of files in the archive.

Parameters for "List" Operation
------------------------------------------------------------
	-ZipOperation List
	-ZipFilePath (Full path and zip file must already exist)
	-Switches (Optional)
	-ZipListProperty (Optional, defaults to All)
	-ZipListOutputFile (Optional, file itself doesn't need to already exist, but the parent path does.)

Example List Calls:
#List all properties to console
.\TestZipFileListing2.ps1 -ZipOperation List -ZipFilePath C:\Util\_IamHere\_NewZip.zip 
#List Name property to console
.\TestZipFileListing2.ps1 -ZipOperation List -ZipFilePath C:\Util\_IamHere\_NewZip.zip -ZipListProperty Name
#List Name property to Output file
.\TestZipFileListing2.ps1 -ZipOperation List -ZipFilePath C:\Util\_IamHere\_NewZip.zip -ZipListProperty Name -ZipListOutputFile C:\Util\_OutputFile.txt
"@ -split "`n" | ForEach-Object Trim

#---------------------------------------------------------

$HelpTextExtract = @"
For Extract Operation:
Purpose: To extract files from an existing archive to a specified location.

Parameters for "Extract" Operation
------------------------------------------------------------
	-ZipOperation Extract
	-ZipFilePath (Full path and zip file must already exist)
	-Switches (Optional)
	-ZipExpandDestination (Folder path to where you want to extract files to)
	-ZipExpandWithFullPath (if $true, will expand with folder paths, if originally saved with paths)
	-Include (Optional, defaults to *)
	-Exclude (Optional)
	-Recurse (Optional, defaults to $false)
	-Force (Optional, overwrite existing files if $true, defaults to $false)

Example Extract Calls:
# Extract the contents of _NewZip.zip to folder C:\Util\_IamHere, and keep original paths. Exclude the Archive
# folder in the zip file.  If files already exist, overwrite them.
.\TestZipFileListing2.ps1 -ZipOperation Extract -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -ZipExpandDestination C:\Util\_IamHere -ZipExpandWithFullPath -Exclude Archive -Recurse -Force

#Extract the contents of _NewZip.zip to folder C:\Util\_IamHere, and only extract the Archive folder inside the
#zip file, and force the overwrite of existing files.
.\TestZipFileListing2.ps1 -ZipOperation Extract -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -ZipExpandDestination C:\Util\_IamHere -ZipExpandWithFullPath -Include Archive -Recurse -Force
"@ -split "`n" | ForEach-Object Trim

#---------------------------------------------------------

$HelpTextNew = @"
For New Operation:
Purpose: To create a new archive and add files to it. If the archive already exists, then delete it and recreate it.

Parameters for "New" Operation
------------------------------------------------------------
	The archive type, 7z or zip, is determined by the extension of the ZipFilePath name
	-ZipOperation New
	-ZipFilePath (Note: will create Full path if it doesn't already exist.)
	-Switches (Optional)
	-TargetFilePath (Optional, defaults to current directory. If given,)
	-Include (Optional, defaults to *)
	-Exclude (Optional)
	-Recurse (Optional, defaults to $false)
	-StorePath (Optional, defaults to $false)

Example New Calls:
#Create the archive with files not already in the archive or files that have been modified.
.\TestZipFileListing2.ps1 -ZipOperation New -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\Logs' -Include *.txt,*.log -Exclude 123.txt,SomeNew*.txt -StorePath -Recurse -Verbose
#Create archive using -Include directive
.\TestZipFileListing2.ps1 -ZipOperation New -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\STJ''s' -Include * -StorePath -Recurse -Verbose
#Create archive by omitting the -Include directive
.\TestZipFileListing2.ps1 -ZipOperation New -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\STJ''s' -StorePath -Recurse -Verbose
"@ -split "`n" | ForEach-Object Trim

#---------------------------------------------------------

$HelpTextUpdate = @"
For Update Operation:
Purpose: To update files in the zip file. If archive file is missing, it is created and files added.
	If a new archive, the archive type, 7z or zip, is determined by the extension of the ZipFilePath name.

Parameters for "Update" Operation
------------------------------------------------------------
	-ZipOperation Update
	-ZipFilePath (Note: will create Full path if it doesn't already exist.)
	-Switches (Optional)
	-TargetFilePath (Optional, defaults to current directory. If given,)
	-Include (Optional, defaults to *)
	-Exclude (Optional)
	-Recurse (Optional, defaults to $false)
	-StorePath (Optional, defaults to $false)

Example Update Calls:
#Update the archive with files not already in the archive or files that have been modified.
.\TestZipFileListing2.ps1 -ZipOperation Update -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\Logs' -Include *.txt,*.log -Exclude 123.txt,SomeNew*.txt -StorePath -Recurse -Verbose
#Update everything using -Include directive
.\TestZipFileListing2.ps1 -ZipOperation Update -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\STJ''s' -Include * -StorePath -Recurse -Verbose
#Update everything by omitting the -Include directive
.\TestZipFileListing2.ps1 -ZipOperation Update -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\STJ''s' -StorePath -Recurse -Verbose
"@ -split "`n" | ForEach-Object Trim

#---------------------------------------------------------

$HelpTextAdd = @"
For Add Operation:
Purpose:  Add files to an existing archive. If archive doesn't exist, it is created.
	If a new archive, the archive type, 7z or zip, is determined by the extension of the ZipFilePath name.

Parameters for "Add" Operation
------------------------------------------------------------
	-ZipOperation Add
    -ZipFilePath  (Note: will create Full path if it doesn't already exist.)
	-Switches (Optional)
	-TargetFilePath (Optional, defaults to current directory. If given,)
	-Include (Optional, defaults to *)
	-Exclude (Optional)
	-Recurse (Optional, defaults to $false)
	-StorePath (Optional, defaults to $false)

Example Add Calls:
#Include specific file specs and Exclude specific file specs.
.\TestZipFileListing2.ps1 -ZipOperation Add -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\Logs' -Include *.txt,*.log -Exclude 123.txt,SomeNew*.txt -StorePath -Recurse -Verbose -Debug
#Include everything using -Include directive
.\TestZipFileListing2.ps1 -ZipOperation Add -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\STJ''s' -Include * -StorePath -Recurse -Verbose
#Include everything by omitting the -Include directive
.\TestZipFileListing2.ps1 -ZipOperation Add -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip' -TargetFilePath 'C:\Util\STJ''s' -StorePath -Recurse -Verbose
"@ -split "`n" | ForEach-Object Trim

#---------------------------------------------------------

$HelpTextTest = @"
For Test Operation:
Purpose: To test the integrity of the archive file

Parameters for "Test" Operation
------------------------------------------------------------
	-ZipOperation Test  or leave off of commandline.
	-ZipFilePath  (Full path and zip file must already exist)
	-Switches (Optional)
	-Verbose (Use the Verbose switch to see output to the console)

Example Test Calls:
.\TestZipFileListing2.ps1 -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip'
.\TestZipFileListing2.ps1 -ZipOperation Test -ZipFilePath 'C:\Util\_IamHere\_NewZip.zip'  -Verbose
"@ -split "`n" | ForEach-Object Trim

<#
.SYNOPSIS
    Display Help for the 7Zip operation.
.DESCRIPTION
    Use this cmdlet to be shown how to use this script to Add, Update, List, Extract files in a 7zip archive
.EXAMPLE
    Help-Add

#>
Function Show-7zHelp {
    [CmdletBinding()]
    Param(
        # The operation to perform
        [Parameter(Mandatory=$true)]
        [ValidateSet("Add", "New", "Update", "List", "Extract", "Test")]
        [string]$Operation
    )
    switch ($Operation) {
        "Add"     { $HelpText = $HelpTextAdd     }
        "New"     { $HelpText = $HelpTextNew     }
        "Update"  { $HelpText = $HelpTextUpdate  }
        "List"    { $HelpText = $HelpTextList    }
        "Extract" { $HelpText = $HelpTextExtract }
        "Test"    { $HelpText = $HelpTextTest    }
    }
    foreach ($line in $HelpText) {
        Write-Host $line -ForegroundColor Green
    }

}

