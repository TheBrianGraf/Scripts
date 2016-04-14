
<#	
	===========================================================================
	 Created on:   	4/12/2016 8:41 AM
	 Created by:   	 Brian Graf
	 Twitter:       @vBrianGraf
     Website:       www.vTagion.com
     Github:        www.github.com/vTagion

     USAGE: THIS SCRIPT WILL TAKE A SOURCE VM'S BIOS FILE (NVRAM) AND REPLACE
     THE NVRAM FILE OF EACH VIRTUAL MACHINE IN THE SAME DATASTORE (CREATING
     A BACKUP OF EACH VM'S ORIGINAL NVRAM FILE FIRST). THIS FIXES AT SCALE,
     THE PROBLEM WHERE THE BIOS HAS A FLOPPY DRIVE ENABLED, CAUSING A FLOPPY
     DRIVE TO SHOW UP IN THE GUEST OS EVEN THOUGH NO FLOPPY DRIVE IS ADDED
     IN THE VM HARDWARE.
	
     NOTE: THIS IS NOT AN OFFICIAL SUPPORTED SCRIPT BY VMWARE. THIS SCRIPT WAS
     CREATED BY BRIAN GRAF. IT HAS BEEN TESTED IN HIS HOME LAB. USER SHOULD
     READ THROUGH THE SCRIPT CAREFULLY AND TRY THIS ON A SINGLE OR SMALL
     SUBSET OF VMs PRIOR TO RUNNING THIS AT SCALE. USE AT YOUR OWN RISK.

     NOTE**: THE COPY-DATASTOREITEM CMDLET TAKES ROUGHLY 10-30 SECONDS TO RUN
     EACH TIME. UNDERSTAND THAT THIS MEANS IT COULD TAKE 20-60 SECONDS PER VM
     TO UPDATE COMPLETELY.
	===========================================================================
#>
# ------------- EDIT VARIABLES HERE -----------------

# Connect to vCenter
connect-viserver 10.144.99.9

# Source VM that bios has been updated on
$sourceBiosVM = Get-VM "ExampleVM"

# --------- DO NOT EDIT BEYOND THIS LINE -------------

# Returns the location of the Bios file
$sourceBioslocation = $sourceBiosVM.ExtensionData.LayoutEx.file | where {$_.Name -like "*.nvram*"}

# Returns the datastore the VM is currently on
$sourceDatastore = $sourceBiosVM | Get-Datastore

# Mount a temporary PowerShell drive to the datastore
New-PSDrive -Location $sourcedatastore -Name ds -PSProvider VimDatastore -Root "\"

# Change directory to this newly created drive
Set-Location ds:\

# Create variable of the Bios file
$nvramfile = $sourceBioslocation.name.Split('] ')[2]

# Create array of all VMs on the same datastore as the SourceBiosVM
# NOTE: YOU MAY WANT TO CHANGE WHICH VM'S THIS IS ACTUALLY GETTING. MAKE SURE THAT
# ALL VMs IN THIS VARIABLE ARE VM's WHICH YOU WANT TO UPDATE AND SHOULD HAVE THE
# EXACT SAME BIOS SETTING.
$VMs = (Get-VM -Datastore $sourceDatastore | where {$_.name -ne $sourceBiosVM.name})

# Create an integer to show progress
$i = 1
# Run a loop for each VM
foreach ($VM in $VMs){

# output that shows progress
Write-host "$i of $($VMs.count)" -ForegroundColor Cyan

Write-host "Backing up NVRAM file on $($VM.Name)" -ForegroundColor Yellow

# Find the current VM's NVRAM file
$targetBioslocation = $VM.ExtensionData.LayoutEx.file | where {$_.Name -like "*.nvram*"}

# Create a variable of the NVRAM name
$backupNVRAM = $TargetBioslocation.name.Split('] ')[2]

# Backup the current NVRAM file by copying and adding an extension ".bak"
Copy-DatastoreItem -item $backupNVRAM -Destination ($backupNVRAM + ".bak") -Force

Write-host "Copying new NVRAM file from $($sourcebiosVM.name) to $($VM.Name)" -ForegroundColor Yellow

# Overwrite old NVRAM file with one created from $SourceBiosVM
Copy-DatastoreItem -item $nvramfile -Destination $backupNVRAM -Force

Write-host "Finished copy for $($vm.name)" -foregroundColor Green

# Increase integer for next loop
$i++
 }

 # Change directory back to C drive
 cd c:

 # Unmount the temporary Datastore Drive
 Remove-PSDrive ds

 # Completed! 


