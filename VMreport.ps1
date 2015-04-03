function Get-VMReport {
<#
.SYNOPSIS
 Report on VMs from a CSV
.DESCRIPTION
 This function will allow you report on VMs from a CSV
.PARAMETER CSV
 Parameter used by the function to locate the CSV file 
.EXAMPLE
	PS> Get-VMReport -CSV c:\temp\vms.csv -Output c:\temp\vmreport.csv
  
#>

  param(
  [Parameter(Mandatory=$True,Position=1)]
  [ValidateNotNullOrEmpty()]
  [String]$CSV,
  
  [Parameter(Mandatory=$True,Position=2)]
  [ValidateNotNullOrEmpty()]
  [String]$Output
  )

  process{
  $VMs = @()
  $Clusters = Get-View -ViewType ClusterComputeResource -Property Name,Host
  $Datastores = Get-View -ViewType Datastore -Property Name
  
  Import-CSV $CSV | Foreach-Object{
  $VM = New-Object -TypeName PSObject
  
   $Current = Get-VM $_.name
   $Cluster = $Clusters | where {$_.Host -like $Current.HostID}
   $Datacenter = $cluster | Get-VIObjectByVIView | Get-Datacenter
   $Datastore = $Datastores | where {$_.MoRef -like $Current.DatastoreIDLIst}
   
   $TDS =  ($Current | Get-HardDisk | Measure-Object -Property CapacityKB -Sum).sum/(1024*1024)
   
   $VM | Add-Member -Name Name -MemberType NoteProperty -Value $Current.Name
   $VM | Add-Member -Name NumCPU -MemberType NoteProperty -Value $Current.NumCpu
   $VM | Add-Member -Name MemoryMB -MemberType NoteProperty -Value $Current.MemoryMB
   $VM | Add-Member -Name PowerState -MemberType NoteProperty -Value $Current.PowerState
   $VM | Add-Member -Name Datacenter -MemberType NoteProperty -Value $Datacenter.Name
   $VM | Add-Member -Name Cluster -MemberType NoteProperty -Value $Cluster.Name
   $VM | Add-Member -Name VMHost -MemberType NoteProperty -Value $Current.VMHost
   $VM | Add-Member -Name Datastore -MemberType NoteProperty -Value $Datastore.name
   $VM | Add-Member -Name TotalDiskGB -MemberType NoteProperty -Value $TDS
   $VM | Add-Member -Name ProvisionedSpaceGB -MemberType NoteProperty -Value $Current.ProvisionedSpaceGB
   $VM | Add-Member -Name UsedSpaceGB -MemberType NoteProperty -Value $Current.UsedSpaceGB
   $VM | Add-Member -Name FreeSpace -MemberType NoteProperty -Value ($TDS - $Current.UsedSpaceGB)
   $VMs += $VM
   
 }
  $VMs | Export-Csv -Path $Output -NoTypeInformation -Append
  }

}
