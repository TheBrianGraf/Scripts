function Export-PsHistory {
    <#
        .NOTES
        ===========================================================================
            Created by:   	Brian Graf
            Date:          1/13/2019
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
            PS C:\> Export-PsHistory -File c:\temp\PowerCLISessionHistory.txt -Description "Stuff I've been working on" -OpenExport
    #>
    param (
        [Parameter(Mandatory=$false)][string]$File,
        [Parameter(Mandatory=$false)][string]$Description,
        [Parameter(Mandatory=$false)][switch]$OpenExport
        )
    
    begin {
        # If 'File' parameter is not used
        if (!($File)){$File = ([Environment]::GetFolderPath("MyDocuments")) + "\PsHistory.txt"}

        # Test to see if file exists
        if (!(test-path $file)) {New-Item $file -type file}

        # If switch is used, invoke-Item
        if ($OpenExport) {$invokeItem = $true}
    }
    Process {
        Write-Output "------------------Start of file-----------------" | out-file -Append $File
        if ($Description) {
            Write-Output "$Description" | out-file -Append $File 
        }
        foreach ($line in (get-history)) { 
            $line.Commandline | out-file -Append $File 
        }
        Write-Output "------------------End of file-----------------" | out-file -Append $File
    
    }
    End {
        Write-Host "Export Successful!" -ForegroundColor Green

        if ($invokeItem) {
            invoke-item $file
        }
    } 
    
}

function Set-PsWindowTitle {
        <#
        .NOTES
        ===========================================================================
         Created by:   	Brian Graf
         Date:          1/13/2019
         Organization: 	VMware
         Blog:          http://www.BrianJGraf.com
         Twitter:       @vBrianGraf
         Github:        https://github.com/vtagion
        ===========================================================================
    
        .SYNOPSIS
            This function will update the PowerShell Window Title.
        
        .DESCRIPTION
            If you are like me you will likely have multiple PowerShell sessions open and literally hundreds of lines of commands run.
            There are times you need to close these, or reorganize, etc and the one thing you don't want is to lose all the things
            you've run without saving them. Get-History is a great tool, but why not export that history
    
        .EXAMPLE
            PS C:\> Set-PsWindowTitle -Title "This is my Title"
            PS C:\> 1..100 | % {Set-PsWindowTitle "$_% Complete"; start-sleep -Milliseconds 100}
    #>
    param (
        [Alias('Name')]
        [Parameter(Mandatory=$false)][string]$Title
        )
    begin {

    }
    process {
        $host.ui.RawUI.WindowTitle = “$Title”
    }
    end {

    }

}

function Set-TaskbarNotification {
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
            Create Notifications for scripts in the taskbar
        
        .DESCRIPTION
            I started using this functionality when working with several scripts that would run for extended periods of time. Instead of checking back on the script periodically,
            I can now be informed by a windows notification when it's progress has changed.
    
        .EXAMPLE
            PS C:\> Set-TaskbarNotification -Title "vCheck Script Status" -Message "vCheck has completed 75% of it's queries" -BalloonIcon Info
    
        .EXAMPLE
            PS C:\> Set-TaskbarNotification -Message "Your script has finished running"
        
        .NOTES
            The only mandatory field with this function is the -message parameter. Everything else will get set to a default value
            - Title - This will take the title of the PowerShell window (if you set the titles for your PS Sessions, this comes in handy)
            - Timeout - The default is a 5 second popup
            - BalloonIcon - The default is 'Info'. Options are 'none, info, warning, and error'
            - This will use the PowerShell Icon in the taskbar
    
            ENJOY!
    #>
        [cmdletbinding()]
    Param (
    [string]$Title,
    [Parameter(mandatory=$true)][string]$Message, 
    [ValidateSet("None","Info","Warning","Error")] [string]$BalloonIcon,
    [int]$TimeoutMS
    ) 
    
    begin {
        if (!($Title)) {$Title = $host.ui.rawui.windowTitle }
        if (!($TimeoutMS)) {$TimeoutMS = 5000}
        if (!($BalloonIcon)) {$BalloonIcon = "Info"}
        [string]$IconPath='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    }
    process {
    
        $SysTrayIcon = New-Object System.Windows.Forms.NotifyIcon 
        
        $SysTrayIcon.BalloonTipText  = $Message
        $SysTrayIcon.BalloonTipIcon  = $BalloonIcon
        $SysTrayIcon.BalloonTipTitle = $Title
        $SysTrayIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($IconPath)
        $SysTrayIcon.Text = "Text"
        $SysTrayIcon.Visible = $True 
    }
    end {
        $SysTrayIcon.ShowBalloonTip($Timeout)
    }
}


function Start-EsxSSH {
    <#	
	.NOTES
	===========================================================================
        Created by:   	Brian Graf
        Date:          November 6, 2018
        Organization: 	VMware
        Blog:          www.brianjgraf.com
        Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		Allows you to quickly enable SSH for your ESXi hosts
	
	.DESCRIPTION
		Use this to quickly enable SSH on the ESX Host
	
	.EXAMPLE
				PS C:\> Get-VMHost 'w2-c32-esx.01' | Start-SSH
	
    #>
	[CmdletBinding()]
	param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$VMHost
	)
	
	
	begin
	{
		if ($VMHost.gettype().basetype -is 'system.object')
		{
			write-host	"string"
			$SelectedHost = Get-VMHost $VMhost
		}
		elseif ($VMHost.gettype().basetype -is 'VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl')
		{
			Write-Host "VIObject"
			$SelectedHost = $VMhost
		}
		Else
		{
		Throw "VMHost parameter needs to be a string or a 'VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl' object (Get-VMHost)"
		}
		
	}
	process
	{
		$StartSvc = Start-VMHostService -HostService ($SelectedHost| Get-VMHostService | Where { $_.Key -eq "TSM-SSH" })
		$StartSvc | select VMHost, Key, Running
	}
	end
	{
		
	}
}


function Stop-EsxSSH {
    <#	
        .NOTES
        ===========================================================================
            Created by:   	Brian Graf
            Date:          November 8, 2018
            Organization: 	VMware
            Blog:          www.brianjgraf.com
            Twitter:       @vBrianGraf
        ===========================================================================
        .DESCRIPTION
            Quickly Disable SSH for your ESX Hosts
            
        .SYNOPSIS
            Allows you to quickly disable SSH for your ESXi hosts
        
        .DESCRIPTION
            Description goes here
        
        .EXAMPLE
            PS C:\> Get-VMHost 'w2-c32-esx.01' | Stop-SSH
        
    #>
	[CmdletBinding()]
	param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$VMHost
	)
	
	
	begin
	{
		if ($VMHost.gettype().basetype -is 'system.object')
		{
			write-host	"string"
			$SelectedHost = Get-VMHost $VMhost
		}
		elseif ($VMHost.gettype().basetype -is 'VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl')
		{
			Write-Host "VIObject"
			$SelectedHost = $VMhost
		}
		Else
		{
		Throw "VMHost parameter needs to be a string or a 'VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl' object (Get-VMHost)"
		}
		
	}
	process
	{
		$StartSvc = Stop-VMHostService -HostService ($SelectedHost| Get-VMHostService | Where { $_.Key -eq "TSM-SSH" })
		$StartSvc | select VMHost, Key, Running
	}
	end
	{
		
	}
}

function Invoke-Speech {
    <#	
	.NOTES
	===========================================================================
         Created by:   	Brian Graf
         Date:          September 1, 2018
         Organization: 	VMware
         Blog:          www.brianjgraf.com
         Twitter:       @vBrianGraf
	===========================================================================
	.DESCRIPTION
        Use this function to perform Text-to-Speech operations
        
	.SYNOPSIS
		If you want PowerShell or your scripts to talk to you, this is for you
	
	.DESCRIPTION
		I sometimes use this to have a script talk to me when 
	
	.EXAMPLE
		PS C:\> Invoke-Speech -Text "Your script is 78% complete"
	
	.NOTES
		This does not currently work with PowerShell Core (see: https://github.com/PowerShell/PowerShell/issues/8809)
    #>
    param (
        [Parameter(Mandatory=$false)][string]$Text
    )
    begin {
        Add-Type –AssemblyName System.Speech
        $Speech = New-Object –TypeName System.Speech.Synthesis.SpeechSynthesizer
    }
    process {
        $Speech.Speak("$Text")
    }
    end {}
    
    

}

function Save-InternetFile {
    <#
        .NOTES
        ===========================================================================
            Created by:   	Brian Graf
            Date:          9/18/2018
            Organization: 	VMware
            Blog:          http://www.BrianJGraf.com
            Twitter:       @vBrianGraf
            Github:        https://github.com/vtagion
        ===========================================================================

        .SYNOPSIS
            Use this function to save files from the internet
        
        .DESCRIPTION
            If you need to grab a file from the web, this is an easy way to grab and save the file

        .EXAMPLE
            PS C:\> Save-InternetFile -URI "http://ipv4.download.thinkbroadband.com/512MB.zip" -SaveLocation "c:\temp\512mb.zip" -OpenFile
    #>
    param (
        [Parameter(Mandatory=$false)][string]$URI,
        [Parameter(Mandatory=$false)][string]$SaveLocation,
        [Parameter(Mandatory=$false)][switch]$OpenFile
    )
    
    begin {
        # If switch is used, Invoke-Item
        if ($OpenFile) {$invokeItem = $true}

        if (!($SaveLocation)){$SaveLocation = ([Environment]::GetFolderPath("MyDocuments")) + "\Downloads"}

        # This next line will 10x the performance of Invoke-WebRequest
        $ProgressPreference = 'SilentlyContinue'

        # Make the call to download the file
        Invoke-WebRequest -Uri "$URI" -OutFile "$SaveLocation"

    }

    process {

        # Check to see if the download was successful
        $testlocation = Test-Path -Path $SaveLocation

        if ($testlocation -eq $true){
            Write-Host "Download Successful" -ForegroundColor Green 
        } else {
            Write-Host "File Not Found, Please Try Again" -ForegroundColor Yellow
        }
    }

    end {

        # if the 'OpenFile' switch is used, open the file when it completes
        if ($invokeItem) { 
            invoke-item $file
        }
    }
}

function Invoke-Base64Encode {
    <#
        .NOTES
        ===========================================================================
            Created by:   	Brian Graf
            Date:          10/2/2018
            Organization: 	VMware
            Blog:          http://www.BrianJGraf.com
            Twitter:       @vBrianGraf
            Github:        https://github.com/vtagion
        ===========================================================================

        .SYNOPSIS
            Function to Base64 encode strings or files
        
        .DESCRIPTION
            If you need to encode a string or object, this function will do the heavy lifting

        .EXAMPLE
            PS C:\> Invoke-Base64Encode -ObjectType String -Data "This Is My Text"

            PS C:\> Invoke-Base64Encode -ObjectType File -Data "C:\Temp\photo1.jpg"
    #>
    param (
        [Parameter(Mandatory=$false)][ValidateSet('File','String')]$ObjectType,
        [Parameter(Mandatory=$false)][string]$Data
        
    )
    Begin {
        switch ($ObjectType) {
            "File" {
                $Content = get-content $Data

            }
            "String" {
                $Content = $Data
            }
        }
    }
    Process {
        $toBytes = [System.Text.Encoding]::Unicode.GetBytes($Content)
        $toEncoded = [Convert]::ToBase64String($toBytes)
    }
    End {
        $toEncoded
    }
}

function Invoke-Base64Decode {
    <#
        .NOTES
        ===========================================================================
            Created by:   	Brian Graf
            Date:          10/2/2018
            Organization: 	VMware
            Blog:          http://www.BrianJGraf.com
            Twitter:       @vBrianGraf
            Github:        https://github.com/vtagion
        ===========================================================================

        .SYNOPSIS
            Function to decode a Base64 encoded string
        
        .DESCRIPTION
            If you need to base64 encode a file or a string you can used Invoke-Base64Encode. This function will decode the string or file

        .EXAMPLE
            PS C:\> Invoke-Base64Decode -Data "VABoAGkAcwAgAGkAcwAgAGEAbgAgAGUAeABhAG0AcABsAGUA" 

            PS C:\> Invoke-Base64Decode -Data "VABoAGkAcwAgAGkAcwAgAGEAbgAgAGUAeABhAG0AcABsAGUA" -OutFile "C:\Temp\file.txt"
    #>
    param (
        [Parameter(Mandatory=$true)][string]$Data,
        [Parameter(Mandatory=$false)][string]$OutFile
    )
    Begin {
    }

    Process {
        $toDecoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($Data))
        
    }
    End {
        if ($OutFile) {
            $toDecoded | Out-File $OutFile
        } else {
            $toDecoded
        }
        
    }

}