function Set-WindowTitle {
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          July 7, 2018
	 Organization: 	VMware
     Blog:          www.brianjgraf.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		Change the title of the PowerShell Window
	
	.DESCRIPTION
        I always have a million PowerShell windows up. I decided instead of using the RawUI string every time to update the title of my PS Session I'd just throw it in a function

	.EXAMPLE
		PS C:\> Set-WindowTitle -Title "Running SDDC Properties Query"
#>
[cmdletbinding()]
Param (
    [Parameter(mandatory=$true)][string]$Title
) 
process {
    $host.ui.RawUI.WindowTitle = $Title
}
}
