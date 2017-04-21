function Export-history {
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          4/13/2017
	 Organization: 	VMware
     Blog:          http://www.BrianJGraf.com
     Twitter:       @vBrianGraf
     Github:        https://github.com/vtagion
	===========================================================================

	.SYNOPSIS
		Cmdlet to export all commands run in a PowerShell session to a text file
	
	.DESCRIPTION
	    If you are like me you will likely have multiple PowerShell sessions open and literally hundreds of lines of commands run.
        There are times you need to close these, or reorganize, etc and the one thing you don't want is to lose all the things
        you've run without saving them. Get-History is a great tool, but why not export that history

	.EXAMPLE
		PS C:\> Export-History -File c:\temp\PowerCLISessionHistory.txt
#>
  param (
        $File,
        [string]$Description
    )

begin {
if (!(test-path $file)) {New-Item $file -type file}
}
Process {
    if ($Description) {
        Write-Output "$Description" | out-file -Append $File 
    } Else { Write-Output "------------------Start of file-----------------" | out-file -Append $File 
    
    }
    foreach ($line in (get-history)) { $line.Commandline | out-file -Append $File }
    Write-Output "------------------End of file-----------------" | out-file -Append $File

}
End {
    Write-Host "Export Successful!" -ForegroundColor Green
} 

}