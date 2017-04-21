function find-VmHardwareVersion {
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          January 23, 2017
	 Organization: 	VMware
     Blog:          www.vtagion.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		Find Hardware Version of virtual Machines
	
	.DESCRIPTION
	    If you are looking to upgrade your Virtual Machine Hardware, you should know what version each is on. Use this to query your Hardware version and if it is already set to upgrade at next power-on or not.

	.EXAMPLE
		PS C:\> Find-VmHardwareVersion -ReturnAllVersions -SortbyVersion

    .EXAMPLE
		PS C:\> Find-VmHardwareVersion -ReturnAllVersions

    .EXAMPLE
		PS C:\> Find-VmHardwareVersion -Version vmx-08
	
	.NOTES
		You can specify VM(s) with the -VM parameter. If not, it will query all VM's.
        You can tab through the values for the -Version parameter
#>
	param (
    [Parameter(Position = 0,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM,
    [ValidateSet("vmx-08", "vmx-09", "vmx-10","vmx-11", "vmx-12","vmx-13")]
    #[Parameter(ParameterSetName=’Version’)]	
    [String]$Version,
    #[Parameter(ParameterSetName=’ReturnAll’)]
    [switch]$ReturnAllVersions,
    [switch]$SortbyVersion
   	)
begin {
if (!$VM) {$VM = Get-VM}}
process{

    # Retuns all VMs selected with their Hardware Version
    if ($ReturnAllVersions) {

        # If "SortbyVersion switch is true, order by version number"
        if ($SortbyVersion) {
            $VM | select Name, @{Name="HardwareVersion";Expression={$_.extensiondata.config.version}}, PowerState, NumCPU, MemoryGB, @{Name="UpgradePolicy";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.UpgradePolicy}},@{Name="Status";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.ScheduledHardwareUpgradeStatus}},@{Name="Fault";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.Fault}} | Sort-Object -Property "HardwareVersion" | ft -AutoSize

        # otherwise return it regular
        } else {
            $VM | select Name, @{Name="HardwareVersion";Expression={$_.extensiondata.config.version}}, PowerState, NumCPU, MemoryGB, @{Name="UpgradePolicy";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.UpgradePolicy}},@{Name="Status";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.ScheduledHardwareUpgradeStatus}},@{Name="Fault";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.Fault}} | Sort-Object -Property "Name" | ft -AutoSize
        }
    # If the "Return All" switch is not set, run against everything
    } else {
        $VM | where {$_.extensiondata.Config.version -like $Version} | select Name, @{Name="HardwareVersion";Expression={$_.extensiondata.config.version}}, PowerState, NumCPU, MemoryGB, @{Name="UpgradePolicy";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.UpgradePolicy}},@{Name="Status";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.ScheduledHardwareUpgradeStatus}},@{Name="Fault";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.Fault}} | Sort-Object -Property "Name" | ft -AutoSize
    }
}
end {}
}

function Update-VmHardware { 
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          January 23, 2017
	 Organization: 	VMware
     Blog:          www.vtagion.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		This will allow users to set VMs to update the VM Hardware version either at next power-on, or at every power-on
	
	.DESCRIPTION
	

	.EXAMPLE
		PS C:\> Update-VmHardware -VM (Get-VM) -Policy onSoftPowerOff -Version vmx-13

    .EXAMPLE
		PS C:\> find-VmHardwareVersion -Version VMX-08 | Update-VmHardware -VM (Get-VM) -Policy onSoftPowerOff -Version vmx-13

	.EXAMPLE
		PS C:\> Update-VmHardware -VM (Get-VM MGMT-AD) -Policy always -Version vmx-13

	.EXAMPLE
		PS C:\> Get-VM MGMT-AD | Update-VmHardware -Policy always -Version vmx-13
	
	.NOTES
		You can tab-complete both the -Policy and -Version parameters

        If a VM is powered-off during this action, the VM will need to be powered-on and then soft-powered off for this to take effect
        
        versions:
        vmx-08 - vsphere 5.0 and later
        vmx-09 - vsphere 5.1 and later
        vmx-10 - vsphere 5.5 and later
        vmx-11 - vsphere 6.0 and later
        vmx-12 - workstation 12 and later
        vmx-13 - vsphere 6.5 and later

#>

	param (
	[Parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM,
	[ValidateSet("onSoftPowerOff", "always", "never")]
	[String]$Policy,
    [ValidateSet("vmx-08", "vmx-09", "vmx-10","vmx-11", "vmx-12","vmx-13")]
	[String]$Version
	
	)
begin{
    $vmarray = @()
}
process{
    foreach ($obj in $VM) 
    {
        $vmarray += $obj.name 
        write-host "$($obj.name): Querying" -ForegroundColor Cyan
        $ObjVersion = $obj.extensiondata.config.version
        $CurrentVersion = $ObjVersion.Split("-")[1]
        $NewVersion = $Version.Split("-")[1]
        if ($NewVersion -gt $CurrentVersion) {
            write-host "$($obj.name): VM Hardware ($Version) is greater than the current version ($ObjVersion), Proceeding" -ForegroundColor Cyan
            $VMView = $obj | get-view
            $spec = New-Object -TypeName VMware.Vim.VirtualMachineConfigSpec
            $spec.ScheduledHardwareUpgradeInfo = New-Object -TypeName VMware.Vim.ScheduledHardwareUpgradeInfo
            $spec.ScheduledHardwareUpgradeInfo.UpgradePolicy = $Policy
            $spec.ScheduledHardwareUpgradeInfo.VersionKey = $Version
            $VMView.ReconfigVM_Task($spec) | Out-Null
            write-host "$($obj.name): Task run, moving on to next VM" -ForegroundColor Cyan
        } else {
        Write-Error "$($Obj.Name) is a higher VM Hardware Version: ($ObjVersion) than the one you have selected: ($Version). Skipping $($Obj.Name)"}
 
    }
   

}
end{   
    # After updating all of the VMs in the array 
    #$VMResults = Get-VM $vmarray
    #$VMResults | select Name, @{Name="HardwareVersion";Expression={$_.extensiondata.config.version}}, PowerState, NumCPU, MemoryGB, @{Name="NewHardwareVersion";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.VersionKey}}, @{Name="UpgradePolicy";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.UpgradePolicy}},@{Name="Status";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.ScheduledHardwareUpgradeStatus}},@{Name="Fault";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.Fault}} | Sort-Object -Property "Name" | ft -AutoSize
}
}


function Remove-VmHardwareUpdate { 
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          January 23, 2017
	 Organization: 	VMware
     Blog:          www.vtagion.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		This will allow users to set VMs to update the VM Hardware version either at next power-on, or at every power-on
	
	.DESCRIPTION
	

	.EXAMPLE
		PS C:\> Remove-VmHardwareUpdate -VM (Get-VM) -Verbose

#>

param (
	[Parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM
)
process{
    #$vmarray = @()
    foreach ($obj in $VM) 
    {
        #$vmarray += $obj.name
        write-host "$($obj.name): Removing VMHardware Update task" -ForegroundColor Cyan
        $VMView = $obj | get-view
        $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $spec.scheduledHardwareUpgradeInfo = New-Object VMware.Vim.ScheduledHardwareUpgradeInfo
        $spec.scheduledHardwareUpgradeInfo.upgradePolicy = 'never'
        $spec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec[] (0)
        $VMView.ReconfigVM_Task($spec) | Out-Null
        write-host "$($obj.name): Task run, moving on to next VM" -ForegroundColor Cyan
    }
    
}
end {
    # After updating all of the VMs in the array
    #$VMResults = Get-VM $vmarray
    #$VMResults | select Name, @{Name="HardwareVersion";Expression={$_.extensiondata.config.version}}, PowerState, NumCPU, MemoryGB, @{Name="NewHardwareVersion";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.VersionKey}}, @{Name="UpgradePolicy";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.UpgradePolicy}},@{Name="Status";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.ScheduledHardwareUpgradeStatus}},@{Name="Fault";Expression={$_.extensiondata.Config.ScheduledHardwareUpgradeInfo.Fault}} | Sort-Object -Property "Name" | ft -AutoSize

}
}