#Enable/Disable Predictive DRS

Get-cluster | where {$_.ExtensionData.ConfigurationEx.ProactiveDRsConfig.Enabled -eq $False}

#check to see if DRS is enabled


#

$cls = Get-cluster | Get-View
$spec = New-Object VMware.Vim.ClusterConfigSpecEx
$spec.ProactiveDrsConfig = New-Object VMware.Vim.ClusterProactiveDrsConfigInfo
$spec.ProactiveDrsConfig.Enabled = $true
$cls.ReconfigureComputeResource_Task($spec, $true)


Function Get-pDRS {
	param (
	[Parameter(Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true)]
	$Cluster
	)
	Begin {}
    Process {Get-Cluster | Select Name, @{Name="pDRS_Status";Expression={$_.ExtensionData.ConfigurationEx.ProactiveDRSConfig.Enabled}} }
    End {}
}

Get-pDRS -Cluster (Get-Cluster)

Function Set-pDRS
{
	param (
	[Parameter(Position = 0,
			Mandatory = $true,
			ValueFromPipeline = $true)]
	$Cluster,
	[Parameter(ParameterSetName='Basic', Mandatory = $false)]
	[switch]$Enabled,
	[Parameter(ParameterSetName = 'Detailed', Mandatory = $false)]
	[switch] $Disabled
	
	)
	Begin {} 
    Process {
 
        foreach ($cls in $cluster) {
            
           switch ($Cls.gettype().name) {
        "ClusterImpl" {
            $cls = $cls | get-view
        }
        "String" {
            $cls = Get-Cluster $cls | Get-View

        }
        }

            $spec = New-Object VMware.Vim.ClusterConfigSpecEx
            $spec.ProactiveDrsConfig = New-Object VMware.Vim.ClusterProactiveDrsConfigInfo
            if ($Enabled) {
                $spec.ProactiveDrsConfig.Enabled = $true
            } else {
                $spec.ProactiveDrsConfig.Enabled = $false
            }
            $cls.ReconfigureComputeResource_Task($spec, $true) | out-null
            $cls.UpdateViewData()
            $cls | select Name, @{Name="pDRS_Status";Expression={$_.ConfigurationEx.ProactiveDRSConfig.Enabled}}
        }
        
    }
    End {}
}

