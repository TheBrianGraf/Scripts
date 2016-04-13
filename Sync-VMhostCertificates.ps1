function Sync-VMhostCertificates {
<#    
      .NOTES
      ===========================================================================
      Created by:      Brian Graf
      Twitter:         @vBrianGraf
      Blog:                  www.vTagion.com
      Created on:      7/14/2015 11:31 AM      
      ===========================================================================
      .DESCRIPTION
            This function will allow you to refresh the certificate information of 
            an ESXi host
      .PARAMETER Cluster
            The Cluster as an object rather than a string.
            $Mycluster = Get-Cluster Prod-US-West-01
    .PARAMETER VMhost
            The VMhost as an object rather than a string.
            $Myhost = Get-VMhost 10.144.99.25
      .EXAMPLE
            # refresh the certificates on all hosts in a specific cluster
            $mycluster = Get-Cluster Prod-US-West-01
            Sync-VMhostCertificates -Cluster $mycluster
      
      .EXAMPLE
            # refresh the certificate of a single host
            $myhost = Get-VMhost 10.144.99.25
            Sync-VMhostCertificates -VMhost $myhost
            
      .EXAMPLE
            # refresh the certificate of all ESXi hosts
            Sync-VMhostCertificates -VMhost (Get-VMhost)
#>
      param(
      [Parameter(Mandatory = $true,
         ValueFromPipeline = $true,
         HelpMessage = "You must choose a cluster object",
         ParameterSetName = 'cluster')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ComputeResourceImpl]$Cluster,
      [Parameter(Mandatory = $true,
         ValueFromPipeline = $true,
         HelpMessage = "You must choose an ESXi Host Object",
         ParameterSetName = 'hosts')]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$Vmhost
      )
      Begin {
            if ($Cluster -ne $null) {
                  $Hosts = $Cluster | Get-VMHost
            }
            if ($Vmhost -ne $null) {
                  $Hosts = $Vmhost
            }
      }
      process {
            foreach ($esx in $Hosts) {
                  if ($esx.ConnectionState -eq "Connected" -and $esx.PowerState -eq "PoweredOn") {
                        $hostid = $esx | Get-View
                        Write-Host "Refreshing Certificate on $($esx.name)" -ForegroundColor Green
                        $hostParam = New-Object VMware.Vim.ManagedObjectReference[] (1)
                        $hostParam[0] = New-Object VMware.Vim.ManagedObjectReference
                        $hostParam[0].value = $hostid.moref.value
                        $hostParam[0].type = 'HostSystem'
                        $_this = Get-View -Id 'CertificateManager-certificateManager'
                        $mytask = $_this.CertMgrRefreshCertificates_Task($hostParam)
                        $task = Get-Task -Id $mytask | select Id, Name, State
                        Write-Host "Task = $($task.Id), Name = $($task.Name), State = $($task.State)"
                        Write-Host ""
                  } else {
                  Write-Warning "$($esx.Name) is either not Powered On or is Not Connected and will not have it's certificate refreshed"
                  Continue
                  }
            }
      }
}
