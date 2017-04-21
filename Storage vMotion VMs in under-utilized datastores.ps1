<#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          January 5, 2017
	 Organization: 	VMware
     Blog:          www.vtagion.com
     Twitter:       @vBrianGraf
	===========================================================================
	
	.DESCRIPTION
		Once PowerCLI session is connected to vCenter, this script will go through each cluster, one at a time and look for
        Datastores that are underutilized (less than 20%) and storage vMotion VMs on these datastores to more utilized datastores
#>

# Cycle through each cluster in vCenter
foreach ($cls in (Get-Cluster)) {
    
    # several arrays used to hold names
    $allDS = @()
    $purgeDS = @()
    $usableDS = @()

    # Return all datastores, foreach-do the following
    foreach ($ds in ($cls | Get-Datastore)) {
        $allds += $ds
         #calculate percentage free
         $Calc = ($ds.freespaceGB / $ds.CapacityGB)
     
         #change result to a percentage
         $percent = "{0:P0}" -f $Calc
     
         if ($percent -gt 86) {
            $PurgeDS += $DS
            # Return all datastores that are 80% or more free
            write-host "$($ds.name) - $percent free" -ForegroundColor Yellow
         }
    
    }
    # Compare all datastores to the ones we want to purge to create usable/target datastores
    Compare-object $allDS $purgeDS | foreach {
        $usableds += $_.inputobject  
    }
   
    # start purging the datastores by moving VMs to more-utilized Datastores
    foreach ($purgingDS in $purgeDS) {

        # Check to see if each datastore with more than 80% free space doesn't have any VM's
        if (! (get-vm -Datastore $purgeds)) {write-host "$($purgingDS.name) does not have any VM's. Proceeding to next Datastore" -ForegroundColor Green} else {

          # If the datastore contains VM's, get all the VMs on the current datastore from above
          foreach ($VM in (Get-VM -datastore $purgingDS)){

              # Notify that the VM needs to be sVMotioned
              write-host "VM: $($VM.name) in $purgingDS needs to be Storage vMotioned" -ForegroundColor Cyan
      
              # Choose a new datastore that is: Not one that will be purged, whose free space after moving the current VM will still have at least 20% free space, pick the one with the most freespace
              $targetDS = $usableDS |where { ($_.freespaceGB -gt ($VM.UsedSpaceGB + (.2 * $_.CapacityGB)))} | Sort-Object freespaceGB -Descending | select -First 1

              # Notify that the VM will now be sVMotioned
              write-host "Moving $($VM.name) to $($targetDS.name)" -ForegroundColor Cyan
      
              # perform Storage vMotion. (Could also add '-runasync' to below command but not sure if it will accurately calculate the used space if other VM's are being vmotioned to given datastores)
              Move-VM $VM -datastore $targetDS
          }
       }
    }
}
     
    New-vicredentialstoreitem