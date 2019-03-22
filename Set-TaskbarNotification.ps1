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
