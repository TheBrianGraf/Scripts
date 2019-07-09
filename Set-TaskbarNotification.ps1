function Set-TaskbarNotification
{
    <#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          July 7, 2018
	 Organization: 	VMware
     Twitter:       @vBrianGraf
	===========================================================================
	.SYNOPSIS
		Create Notifications for scripts in the taskbar
	.DESCRIPTION
        I started using this functionality when working with several scripts that would run for extended periods of time. Instead of checking back on the script periodically,
        I can now be informed by a windows notification when it's progress has changed.
    .PARAMETER Title
        Not Required, Amends the title of the Notification.
    .PARAMETER Message
        Required, Text of the Message to be displayed.
    .PARAMETER BallonIcon
        Not Required, Changes the Icon diplayed in the message. Default is 'Info'.
    .PARAMETER TimeoutMS
        Not Required, Changes the duration the message is displayed. Default is 5000.
	.EXAMPLE
		Set-TaskbarNotification -Title "vCheck Script Status" -Message "vCheck has completed 75% of it's queries" -BalloonIcon Info
    .EXAMPLE
		Set-TaskbarNotification -Message "Your script has finished running"
	.NOTES
        The only mandatory field with this function is the -message parameter. Everything else will get set to a default value
        ENJOY!
    .LINK
        www.brianjgraf.com
#>
    [cmdletbinding()]
    Param (
        [string]$Title = $host.ui.rawui.windowTitle,
        [Parameter(mandatory = $true)][string]$Message, 
        [ValidateSet("None", "Info", "Warning", "Error")] [string]$BalloonIcon = "Info",
        [int]$TimeoutMS = 5000
    ) 

    begin
    {
        [string]$IconPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    }
    process
    {

        $SysTrayIcon = New-Object System.Windows.Forms.NotifyIcon 
        $SysTrayIcon.BalloonTipText = $Message
        $SysTrayIcon.BalloonTipIcon = $BalloonIcon
        $SysTrayIcon.BalloonTipTitle = $Title
        $SysTrayIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($IconPath)
        $SysTrayIcon.Text = "Text"
        $SysTrayIcon.Visible = $True 
    }
    end
    {
        $SysTrayIcon.ShowBalloonTip($TimeoutMS)
    }
}
