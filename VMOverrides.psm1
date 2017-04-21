
Function Get-VMOverride
{
	[CmdletBinding(DefaultParameterSetName='integrated')]
	param (
	[Parameter(Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM,
	[Parameter(ParameterSetName='Basic', Mandatory = $false)]
	[switch]$Basic,
	[Parameter(ParameterSetName = 'Detailed', Mandatory = $false)]
	[switch] $Detailed
	
	)
	Begin { if (!($Basic) -and (!($Detailed))) {$Basic = $true } }
	Process
	{
		Foreach ($Obj in $VM)
		{
			$cls = $Obj | Get-Cluster
			
			if ($cls.ExtensionData.ConfigurationEx.DrsVmConfig.key -eq $Obj.Id -or $cls.ExtensionData.ConfigurationEx.DasVmConfig.key -eq $Obj.Id)
			{
				
				$DRSOverride = $cls.extensiondata.Configurationex.DrsVmConfig | Where { $_.key -eq $Obj.Id }
				$HAOverride = $cls.extensiondata.Configurationex.DasVmConfig | Where { $_.key -eq $Obj.Id }
				
				if ($DRSOverride)
				{
					$DRSOE = $DRSOverride.enabled
					$DRSBehavior = $DRSOverride.Behavior
				}
				
				if ($HAOverride)
				{
					$RestartPriority = $HAOverride.DasSettings.RestartPriority
					$RestartPriorityTimeout = $HAOverride.DasSettings.RestartPriorityTimeout
					
					If ($HAOverride.DasSettings.RestartPriorityTimeout -eq "-1")
					{
						$RestartPriorityTimeout = "Default"
					}
					$PowerOffOnIsolation = $HAOverride.DasSettings.PowerOffOnIsolation
					$IsolationResponse = $HAOverride.DasSettings.IsolationResponse
					
					switch ($HAOverride.DasSettings.IsolationResponse)
					{
						"poweroff" { $IsolationResponse = "Power-Off and Restart VMs" }
						"shutdown" { $IsolationResponse = "Shutdown and Restart VMs" }
						"clusterIsolationResponse" { $IsolationResponse = $cls.ExtensionData.ConfigurationEx.DasConfig.DefaultVmSettings.IsolationResponse }
						"none" { $IsolationResponse = "No action taken" }
					}
					
					#ToolsMonitoring
					#$HAOverride.DasSettings.VmToolsMonitoringSettings
					$ToolsEnabled = $HAOverride.DasSettings.VmToolsMonitoringSettings.Enabled
					$Monitoring = $HAOverride.DasSettings.VmToolsMonitoringSettings.VmMonitoring
					$ClusterSettings = $HAOverride.DasSettings.VmToolsMonitoringSettings.ClusterSettings
					$FailureInterval = $HAOverride.DasSettings.VmToolsMonitoringSettings.FailureInterval
					$MinUpTime = $HAOverride.DasSettings.VmToolsMonitoringSettings.MinUpTime
					$MaxFailures = $HAOverride.DasSettings.VmToolsMonitoringSettings.MaxFailures
					$MaxFailureWindow = $HAOverride.DasSettings.VmToolsMonitoringSettings.MaxFailureWindow
					
					if (!($ToolsEnabled = $HAOverride.DasSettings.VmToolsMonitoringSettings.Enabled))
					{
						$ToolsEnabled = $cls.ExtensionData.ConfigurationEx.DasConfig.VMMonitoring
						
					}
					
					#VMCP
					#$HAOverride.DasSettings.VmComponentProtectionSettings
					$APD = $HAOverride.DasSettings.VmComponentProtectionSettings.VmStorageProtectionForAPD
					$APDTimeout = $HAOverride.DasSettings.VmComponentProtectionSettings.EnableAPDTimeoutForHosts
					$APDDelay = $HAOverride.DasSettings.VmComponentProtectionSettings.VmTerminateDelayForAPDSec
					$APDReaction = $HAOverride.DasSettings.VmComponentProtectionSettings.VmReactionOnAPDCleared
					$PDLProtection = $HAOverride.DasSettings.VmComponentProtectionSettings.VmStorageProtectionForPDL
					
					if ($cls.ExtensionData.ConfigurationEx.DasConfig.VmComponentProtecting -eq 'disabled')
					{
						$APD = "disabled at cluster level"
						$APDTimeout = "disabled at cluster level"
						$APDDelay = "disabled at cluster level"
						$APDReaction = "disabled at cluster level"
						$PDLProtection = "disabled at cluster level"
					}
					
				}
				if ($Detailed)
				{
					$outputobj = [Ordered]@{
						VM = $Obj.Name;
						Cluster = $cls.name;
						DRSOverride = $DRSOE;
						DRSBehavior = $DRSBehavior;
						HARestartPriority = $RestartPriority;
						HARestartTimeout = $RestartPriorityTimeout;
						HARestartResponse = $IsolationResponse;
						PowerOffOnIsolation = $PowerOffOnIsolation;
						ToolsEnabled = $ToolsEnabled;
						Monitoring = $Monitoring;
						MonitoringClusterSettings = $ClusterSettings;
						FailureInterval = $FailureInterval;
						MinUpTime = $MinUpTime;
						MaxFailures = $MaxFailures;
						MaxFailureWindow = $MaxFailureWindow;
						VMCPAllPathsDown = $APD;
						AllPathsDownTimeout = $APDTimeout;
						AllPathsDownDelay = $APDDelay;
						AllPathsDownReaction = $APDReaction;
						PermanentDeviceLossProtection = $PDLProtection;
						
					}
				}
				
				if ($Basic)
				{
					$outputobj = [Ordered]@{
						VM = $Obj.Name;
						DRSOverride = $DRSOE;
						DRSBehavior = $DRSBehavior;
						HARestartPriority = $RestartPriority;
						HARestartTimeout = $RestartPriorityTimeout;
						HARestartResponse = $IsolationResponse;
						
					}
				}
				
				$Output = New-Object System.Management.Automation.PSObject -Property $outputobj
				
			$Output
			}
			else { continue }
		}

		
	}
}

Function Set-VMOverride
{
	param (
	[Parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM,
	[ValidateSet("FullyAutomated", "PartiallyAutomated", "Manual", "ClusterDefault", "Disabled")]
	[String]$DRSAutomationLevel,
	[Parameter(ParameterSetName="HA",Mandatory=$false)]
	[ValidateSet("Lowest", "Low", "Medium", "High", "Highest", "ClusterDefault")]
	[String]$HARestartPriority,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("ResourcesAllocated", "PoweredOn", "VMToolsDetected", "ClusterDefault")]
	[String]$StartNextVM,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("PowerOff", "Shutdown", "Disabled", "ClusterDefault")]
	[String]$IsolationResponse,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("PowerOff", "Disabled", "IssueEvents", "ClusterDefault")]
	[String]$PDL,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("PowerOffConservative", "PowerOffAggressive", "Disabled", "IssueEvents", "ClusterDefault")]
	[String]$APD,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("Diabled", "ResetVMs", "ClusterDefault")]
	[String]$APDRecovery,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("VMMonitoringOnly", "Disabled", "ClusterDefault")]
	[String]$VMMonitoring,
	[Parameter(ParameterSetName = "HA", Mandatory = $false)]
	[ValidateSet("High", "Medium", "Low")]
	[String]$VMMonitoringSensitivity
	
	)
	Begin
	{
		# if parameters above that are a continuation of parameters used, add 'clusterDefault' value for them
		if (!($StartNextVM) -and ($HARestartPriority)) { }
		# add the others
		
		if ($defaultVIServers[0].version -ne "6.5" -and $HARestartPriority -eq "Lowest") { $HARestartPriority = "Low" }
		if ($defaultVIServers[0].version -ne "6.5" -and $HARestartPriority -eq "Highest") { $HARestartPriority = "High" }
		
	}
		Process
	{
		Foreach ($Obj in $VM)
		{
			$cls = $Obj | Get-Cluster
			#Check to see if Override already exists
			if ($cls.ExtensionData.ConfigurationEx.DrsVmConfig.key -eq $Obj.Id -or $cls.ExtensionData.ConfigurationEx.DasVmConfig.key -eq $Obj.Id)
			{
				#Edit Current	
				#Base Spec
				$spec = New-Object VMware.Vim.ClusterConfigSpecEx
				
				#HA Spec
				$spec.dasVmConfigSpec = New-Object VMware.Vim.ClusterDasVmConfigSpec[] (1)
				
				$spec.dasVmConfigSpec[0] = New-Object VMware.Vim.ClusterDasVmConfigSpec
				$spec.dasVmConfigSpec[0].operation = 'edit'
				$spec.dasVmConfigSpec[0].info = New-Object VMware.Vim.ClusterDasVmConfigInfo
				$spec.dasVmConfigSpec[0].info.dasSettings = New-Object VMware.Vim.ClusterDasVmSettings
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings = New-Object VMware.Vim.ClusterVmComponentProtectionSettings
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmReactionOnAPDCleared = 'useClusterDefault'
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'clusterDefault'
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmTerminateDelayForAPDSec = -1
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmStorageProtectionForPDL = 'clusterDefault'
				$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings = New-Object VMware.Vim.ClusterVmToolsMonitoringSettings
				$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.clusterSettings = $true
				$spec.dasVmConfigSpec[0].info.dasSettings.restartPriority = 'high'
				$spec.dasVmConfigSpec[0].info.dasSettings.isolationResponse = 'clusterIsolationResponse'
				$spec.dasVmConfigSpec[0].info.key = New-Object VMware.Vim.ManagedObjectReference
				$spec.dasVmConfigSpec[0].info.key.value = "$($obj.ExtensionData.MoRef.Value)"
				$spec.dasVmConfigSpec[0].info.key.type = 'VirtualMachine'
				
				#DRS Spec
				$spec.drsVmConfigSpec = New-Object VMware.Vim.ClusterDrsVmConfigSpec[] (1)
				$spec.drsVmConfigSpec[0] = New-Object VMware.Vim.ClusterDrsVmConfigSpec
				$spec.drsVmConfigSpec[0].operation = 'edit'
				$spec.drsVmConfigSpec[0].info = New-Object VMware.Vim.ClusterDrsVmConfigInfo
				$spec.drsVmConfigSpec[0].info.enabled = $false
				$spec.drsVmConfigSpec[0].info.key = New-Object VMware.Vim.ManagedObjectReference
				$spec.drsVmConfigSpec[0].info.key.value = "$($obj.ExtensionData.MoRef.Value)"
				$spec.drsVmConfigSpec[0].info.key.type = 'VirtualMachine'
				
				$modify = $true
				$clsReconfig = $cls | Get-View
				$clsReconfig.ReconfigureComputeResource_Task($spec, $modify)
			}
			else
			{
				#Add New	
				
				#Base Spec
				$spec = New-Object VMware.Vim.ClusterConfigSpecEx
				
				#HA Spec
				$spec.dasVmConfigSpec = New-Object VMware.Vim.ClusterDasVmConfigSpec[] (1)
				
				$spec.dasVmConfigSpec[0] = New-Object VMware.Vim.ClusterDasVmConfigSpec
				$spec.dasVmConfigSpec[0].operation = 'add'
				$spec.dasVmConfigSpec[0].info = New-Object VMware.Vim.ClusterDasVmConfigInfo
				$spec.dasVmConfigSpec[0].info.dasSettings = New-Object VMware.Vim.ClusterDasVmSettings
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings = New-Object VMware.Vim.ClusterVmComponentProtectionSettings
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmReactionOnAPDCleared = 'useClusterDefault'
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmStorageProtectionForAPD = 'clusterDefault'
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmTerminateDelayForAPDSec = -1
				$spec.dasVmConfigSpec[0].info.dasSettings.vmComponentProtectionSettings.vmStorageProtectionForPDL = 'clusterDefault'
				$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings = New-Object VMware.Vim.ClusterVmToolsMonitoringSettings
				$spec.dasVmConfigSpec[0].info.dasSettings.vmToolsMonitoringSettings.clusterSettings = $true
				$spec.dasVmConfigSpec[0].info.dasSettings.restartPriority = 'high'
				$spec.dasVmConfigSpec[0].info.dasSettings.isolationResponse = 'clusterIsolationResponse'
				$spec.dasVmConfigSpec[0].info.key = New-Object VMware.Vim.ManagedObjectReference
				$spec.dasVmConfigSpec[0].info.key.value = "$($obj.ExtensionData.MoRef.Value)"
				$spec.dasVmConfigSpec[0].info.key.type = 'VirtualMachine'
				
				#DRS Spec
				$spec.drsVmConfigSpec = New-Object VMware.Vim.ClusterDrsVmConfigSpec[] (1)
				$spec.drsVmConfigSpec[0] = New-Object VMware.Vim.ClusterDrsVmConfigSpec
				$spec.drsVmConfigSpec[0].operation = 'add'
				$spec.drsVmConfigSpec[0].info = New-Object VMware.Vim.ClusterDrsVmConfigInfo
				$spec.drsVmConfigSpec[0].info.enabled = $false
				$spec.drsVmConfigSpec[0].info.key = New-Object VMware.Vim.ManagedObjectReference
				$spec.drsVmConfigSpec[0].info.key.value = "$($obj.ExtensionData.MoRef.Value)"
				$spec.drsVmConfigSpec[0].info.key.type = 'VirtualMachine'
				
				$modify = $true
				$clsReconfig = $cls | Get-View
				$clsReconfig.ReconfigureComputeResource_Task($spec, $modify)
			}
			
		}
	}
	End { }
}

Function Remove-VMOverride
{
	[cmdletBinding(SupportsShouldProcess = $true, ConfirmImpact='High')]
	param (
	[Parameter(Position = 0,
			   Mandatory = $true,
			   ValueFromPipeline = $true)]
	[VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl[]]$VM,
	[Parameter(ParameterSetName = 'Single')]
	[switch]$RemoveDRSOverride,
	[Parameter(ParameterSetName = 'Single')]
	[switch]$RemoveHAOverride,
	[Parameter(ParameterSetName = 'Double')]
	[switch]$RemoveBoth 
	)
	begin
	{
		if (!($RemoveDRSOverride) -and (!($RemoveHAOverride)) -and (!($RemoveBoth))) { $RemoveBoth = $true }
	}
	process
	{
		foreach ($obj in $VM)
		{
			$cls = $obj | get-cluster
			if ($cls.ExtensionData.ConfigurationEx.DrsVmConfig.key -eq $Obj.Id -or $cls.ExtensionData.ConfigurationEx.DasVmConfig.key -eq $Obj.Id)
			{
				$spec = New-Object VMware.Vim.ClusterConfigSpecEx
				
				if ($RemoveDRSOverride -or $RemoveBoth)
				{
					if ($cls.ExtensionData.ConfigurationEx.DrsVmConfig.key -eq $Obj.Id)
					{
						$spec.drsVmConfigSpec = New-Object VMware.Vim.ClusterDrsVmConfigSpec[] (1)
						$spec.drsVmConfigSpec[0] = New-Object VMware.Vim.ClusterDrsVmConfigSpec
						$spec.drsVmConfigSpec[0].operation = 'remove'
						$spec.drsVmConfigSpec[0].removeKey = New-Object VMware.Vim.ManagedObjectReference
						$spec.drsVmConfigSpec[0].removeKey.value = "$($obj.ExtensionData.MoRef.Value)"
						$spec.drsVmConfigSpec[0].removeKey.type = 'VirtualMachine'
						$modify = $true

					}
				} #end RemoveDRSOverride
				if ($RemoveHAOverride -or $RemoveBoth)
				{
					if ($cls.ExtensionData.ConfigurationEx.DasVmConfig.key -eq $Obj.Id)
					{
						$spec.dasVmConfigSpec = New-Object VMware.Vim.ClusterDasVmConfigSpec[] (1)
						$spec.dasVmConfigSpec[0] = New-Object VMware.Vim.ClusterDasVmConfigSpec
						$spec.dasVmConfigSpec[0].operation = 'remove'
						$spec.dasVmConfigSpec[0].removeKey = New-Object VMware.Vim.ManagedObjectReference
						$spec.dasVmConfigSpec[0].removeKey.value = "$($obj.ExtensionData.MoRef.Value)"
						$spec.dasVmConfigSpec[0].removeKey.type = 'VirtualMachine'
						$modify = $true
					}
				} #end RemoveHAOverride
				
				$modify = $true
				$clsReconfig = $cls | Get-View
				$clsReconfig.ReconfigureComputeResource_Task($spec, $modify)
			}
			else { continue }
		} #end Foreach Loop
		
	} #end Process
	end { }
}
