
function Get-vMotionEncryptionConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          October 14, 2016
	 Organization: 	VMware
     Blog:          www.vtagion.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		for vSphere 6.5 and greater you can now choose how VMs are vMotioned.
    The encryption options are: Disabled, Opportunistic, and Required
	
	.DESCRIPTION
		Use this function to get the vMotionEncryption settings for each VM.

    You must use a VM object for the VM parameter:
         (Get-VM) or $VM = Get-VM Exchange*

	.EXAMPLE
		PS C:\> Get-vMotionEncryptionConfig -VM (Get-VM)
	
	.NOTES
		Additional information about the function.
#>
	param (
	[Parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM
	
	)
begin{}
process{
    $VM | Select-Object Name, @{name="vMotionEncryption";Expression={$_.extensiondata.config.MigrateEncryption}}
}
end{}


}

function Set-vMotionEncryptionConfig {
<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          October 14, 2016
	 Organization: 	VMware
     Blog:          www.vtagion.com
     Twitter:       @vBrianGraf
	===========================================================================

	.SYNOPSIS
		for vSphere 6.5 and greater you can now choose how VMs are vMotioned.
    The encryption options are: Disabled, Opportunistic, and Required
	
	.DESCRIPTION
		Use this function to set the vMotionEncryption settings for each VM
    in an automated fashion.

    The 'Encryption' parameter is set up with Tab-Complete for the available
    options.

    You must use a VM object for the VM parameter:
         (Get-VM) or $VM = Get-VM Exchange*

	.EXAMPLE
		PS C:\> Set-vMotionEncryptionConfig -VM (Get-VM) -Encryption opportunistic
	
	.NOTES
		Additional information about the function.
#>

	param (
	[Parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM,
	[ValidateSet("disabled", "opportunistic", "required")]
	[String]$Encryption
	
	)
begin{
    write-host "Working... Please be patient." -ForegroundColor Cyan
}
process{
    foreach ($obj in $VM) 
    {
        $VMView = $obj | get-view
        $config = new-object VMware.Vim.VirtualMachineConfigSpec
        $config.MigrateEncryption = New-object VMware.Vim.VirtualMachineConfigSpecEncryptedVMotionModes
        $config.MigrateEncryption = "$encryption"
    
        $VMView.ReconfigVM($config)
    }
}
end{ 
$VM | Select-Object Name, @{name="vMotionEncryption";Expression={$_.extensiondata.config.MigrateEncryption}} }

}





