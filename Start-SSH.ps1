<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.118
	 Created on:   	4/6/2016 9:04 PM
	 Created by:   	Brian Graf
	 Organization: 	VMware
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
<#
	.SYNOPSIS
		Allows you to quickly enable SSH for your ESXi hosts
	
	.DESCRIPTION
		Description goes here
	
	.EXAMPLE
				PS C:\> GetStart-SSH
	
	.NOTES
		Additional information about the function.
#>
function Start-EsxSSH
{
	[CmdletBinding()]
	param (
	[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$VMHost
		#$VMHost
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