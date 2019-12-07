Function Convert-A1ToNumber {
  <#
  .SYNOPSIS
  This converts Excel A1 format to a column number
  .DESCRIPTION
  See synopsis.
  .PARAMETER number
  Any sequence of letters between "A" and "XFD".
  Lower case input is acceptable.
  #>

Param([parameter(Mandatory=$true)]
    [string]$ColName)

    [int]$value = 0

    $ColName = $ColName.ToUpper()
    $ColNameArray = $ColName.ToCharArray()
    [array]::Reverse($ColNameArray)
    for($i = 0; $i -le $ColNameArray.Length - 1;$i++) {
        if ($i -gt 0) {
            $value += ([math]::Pow(26,$i)) * ([byte][char]$ColNameArray[$i] - 64)
        } else {
            $value =+ ([byte][char]$ColNameArray[$i] - 64)
        }
    }
    if ($value -gt 16384) {
        Write-Warning "Input column letters do not exist in Excel."
        Write-Warning "Value returned is not valid for Excel."
    }
    Return $value
} #End function
