<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          August 1, 2018
	 Organization: 	VMware
     Blog:          www.brianjgraf.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		Loop through the alphabet rather than numbers
	
	.DESCRIPTION
        I had a use-case where I needed to add a letter on the end of a value and continue through the alphabet with it. This code will help you easily loop characters rather than integers.

#>

# Loop through characters instead of numbers
$integerloop=[int][char]'A'

# Move to the next character
$integerloop++

# Display the character
[char]$integerloop

# Example, I love (A,B,C,D,...)
1..5 | % {
$integerloop++
$x = [char]$integerloop
Write-host "I love $x"

}