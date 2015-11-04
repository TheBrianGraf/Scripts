<#	
	.NOTES
	===========================================================================
	 Created on:   	11/3/2015 2:59 PM
	 Created by:   	Brian Graf
     Corporate blog: blogs.vmare.com/powercli
                     blogs.vmware.com/vsphere
     Personal blog: www.vtagion.com
     Twitter:       @vBrianGraf
	 Unsupported Script. This receives no support from VMware     	
	===========================================================================
	.DESCRIPTION
		Assuming you have:
    downloaded Plink.EXE
    created a folder on a shared Datastore and placed the VMtools files in it 
    and your DNS is setup to resolve your hostnames,
     this will allow you to configure all of your hosts to use a shared 
     productlocker for VMware tools. 
#>

# Query all datastores that are currently accessed by more than one ESXi Host
$Datastores = Get-Datastore | where {$_.ExtensionData.Summary.MultipleHostAccess}

# ------------ MENU FOR CHOOSING SHARED DATASTORE  ------------
$menu = @{}

Write-Host "Which Shared Datastore are the VMTools Files Located?:" -ForegroundColor Yellow
    
#Create Dynamic Menu of the Shared Datastores
for ($i=1;$i -le $Datastores.count; $i++) {
    Write-Host "$i. $($Datastores[$i-1].name)"
    $menu.Add($i,($Datastores[$i-1].name))
    }

# Do the following block until a valid choice is selected
do {
    [int]$ans = Read-Host 'Enter selection'
    $selection = $menu.Item($ans)
    if ($selection -eq $null) {
        Write-host "[$ans] was not a valid option. Please try again..." -ForegroundColor Red}else {
        Write-host "Continuing with Shared Datastore: $selection" -ForegroundColor Green 
    }
} until ($selection -ne $null)

# -------------------------------------------------------------

# Name the Datastore variable from the menu item chosen
$Datastore = $Datastores | where {$_.Name -eq $selection}

# See if PSDrive 'PL:' exists, if it does, remove it
if (test-path 'PL:') {Remove-PSDrive PL -Force}

# Create new PSDrive to allow us to interact with the datastore
New-PSDrive -Location $Datastore -Name PL -PSProvider VimDatastore -Root '\' | out-null

# Change Directories to the new PSDrive
cd PL:

# Create a variable with all the folders from this datastore's root level
$folders = get-childitem | ?{ $_.PSIsContainer}

# ---------- MENU FOR CHOOSING PRODUCT LOCKER FOLDER  ---------

$menu2 = @{}

# Prompt for Menu
Write-host "Which Folder is being used for the Shared Product Locker?:" -ForegroundColor Yellow

# Create Menu item for each folder in Datastore
for ($i=1;$i -le $folders.count; $i++) {
        Write-Host "$i. $($folders[$i-1].name)"
        $menu2.Add($i,($folders[$i-1].name))
    }

# Repeat the following block until a valid choice is made
do {
    [int]$ans2 = Read-Host 'Enter selection'
    $selection2 = $menu2.Item($ans)
    if ($selection2 -eq $null) {
        Write-host "[$ans2] was not a valid option. Please try again..." -ForegroundColor Red
    } else {
        Write-host "Continuing with folder: $selection2" -ForegroundColor Green 
    }
} until ($selection2 -ne $null)

# -------------------------------------------------------------

# This is here just for comfort and visibility of user. This could be done in many fewer Test-Path's


if (Test-Path /$selection2){

    # if floppies folder exists, and has more than 1 item inside, move on
    if (Test-Path /$selection2/floppies) {
        Write-Host "Floppy Folder Exists"-ForegroundColor Green 
        $floppyitems = Get-ChildItem /$selection2/floppies/
        if ($floppyitems.count -ge 1) {
            Write-Host "($($floppyitems.count)) Files found in floppies folder" -ForegroundColor Green 
        } 
        # if there is not at least 1 file, throw...
        else {
            cd c:\
            Remove-PSDrive PL -Force
            Throw "No files found in floppies folder. please add files and try again"
        }
        } 
    # if the folder doesn't exist, throw...
    else {
            cd c:\
            Remove-PSDrive PL -Force
            Throw "it appears the floppies folder doesn't exist. add the floppies and vmtools folders with their respective files to the shared datastore"
    }
    # if vmtools folder exists, and has more than 1 item inside, move on
    if (Test-Path /$selection2/vmtools) {
        Write-host "vmtools Folder Exists" -ForegroundColor Green 
        $vmtoolsitems = Get-ChildItem /$selection2/vmtools/
        if ($vmtoolsitems.count -ge 1) {
            Write-Host "($($vmtoolsitems.count)) Files found in vmtools folder" -ForegroundColor Green 
        } 
        else {
            cd c:\
            Remove-PSDrive PL -Force
            Throw "No files found in vmtools folder. please add files and try again"
        }
        }
    # if the folder doesn't exist, throw...
    else {
        cd c:\
        Remove-PSDrive PL -Force
        Throw "it appears the vmtools folder doesn't exist. add the floppies and vmtools folders with their respective files to the shared datastore"
    }
}

# Congrats message at the end of checking the folder structure
Write-host "It appears the folders are setup correctly..." -ForegroundColor Green

# ------------ NEW MENU FOR SETTING VARIABLES ON HOSTS ------------
$title = "Set UserVars.ProductLockerLocation on Hosts"
$message = "Do you want to set this UserVars.ProductLockerLocation on all hosts that have access to Datastore [$selection]?"
$Y = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Yes - Set this on all hosts that see this datastore"
$N = New-Object System.Management.Automation.Host.ChoiceDescription "&No","No - Do Not set this on all hosts that see this datastore"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($Y,$N)
$Result = $host.ui.PromptForChoice($title,$message,$options,0)
# -----------------------------------------------------------------

# Setting ProductLockerLocation on Hosts
Switch ($Result) {
    "0" {
        # Full Path to ProductLockerLocation
        Write-host "Full path to ProductLockerLocation: [vmfs/volumes/$($datastore.name)/$selection2]" -ForegroundColor Green
        # Set value on all hosts that access shared datastore
        Get-AdvancedSetting -entity (Get-VMHost -Datastore $selection) -Name 'UserVars.ProductLockerLocation'| Set-AdvancedSetting -Value "vmfs/volumes/$($datastore.name)/$selection2"
    }
    "1" { 
        Write-Host "By not choosing `"Yes`" you will need to manually update the UserVars.ProductLockerLocation value on each host that has access to Datastore [$($datastore.name)]" -ForegroundColor Yellow
    }

}

# Change drive location to c:\
cd c:\

# Remove the PS Drive for cleanliness
Remove-PSDrive PL -Force

Write-host ""
Write-host ""
Write-host "The final portion of this is to update the SymLinks in the hosts to point to our new ProductLockerLocation. This can be set by either rebooting your ESXi Hosts, or we can set this with remote SSH sessions via Plink.exe" -ForegroundColor Yellow

# ------------ NEW MENU FOR SETTING VARIABLES ON HOSTS ------------
$title1 = "Update SymLinks on ESXi Hosts"
$message1 = "Would you like to have this script do remote SSH sessions instead of reboots?"
$Y1 = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes - Tell me more","Yes - Continue on with this process "
$N1 = New-Object System.Management.Automation.Host.ChoiceDescription "&No - I'll just restart my hosts to update the link instead","No - Exit this script"
$options1 = [System.Management.Automation.Host.ChoiceDescription[]]($Y1,$N1)
$Result1 = $host.ui.PromptForChoice($title1,$message1,$options1,0)
# -----------------------------------------------------------------


# Setting ProductLockerLocation on Hosts
Switch ($Result1) {
    "0" {
        # Full Path to Plink.exe
        do {$plink = read-host "What is the full path to Plink.exe (ex: c:\temp\plink.exe)?"}
        until (Test-Path $plink)

        Write-host ""
        Write-host "This script assumes all ESXi Hosts have the same username and password. If this is not the case you will need to modify this script to accept a CSV with other info" -ForegroundColor Yellow  
        
        # Get encrypted credentials from user for ESXi Hosts
        $creds = (Get-Credential -Message "What is the login for your ESXi Hosts?")
     
        $username = $creds.UserName
        $PW = $creds.GetNetworkCredential().Password

        Write-host ""

        # Each host needs to have SSH enabled to continue
        $SSHON = @()
        $VMhosts = Get-VMHost -Datastore $selection 
        
        # Foreach ESXi Host, see if SSH is running, if it is, add the host to the array
        $VMHosts | % {
        if ($_ |Get-VMHostService | ?{$_.key -eq “TSM-SSH”} | ?{$_.Running -eq $true}) {
            $SSHON += $_.Name
            Write-host "SSH is already running on $($_.Name). adding to array to not be turned off at end of script" -ForegroundColor Yellow
        }
        
        # if not, start SSH
        else {
            Write-host "Starting SSH on $($_.Name)" -ForegroundColor Yellow
            Start-VMHostService -HostService ($_ | Get-VMHostService | ?{ $_.Key -eq “TSM-SSH”} ) -Confirm:$false
        }
        }
         
        #Start PLINK COMMANDS
        $plinkfolder = Get-ChildItem $plink

        # Change directory to Plink location for ease of use
        cd $plinkfolder.directoryname
        $VMHOSTs | foreach {
            
            # Run Plink remote SSH commands for each host
            Write-host "Running remote SSH commands on $($_.Name)." -ForegroundColor Yellow
            Echo Y | ./plink.exe $_.Name -pw $PW -l $username 'rm /productLocker'
            Echo Y | ./plink.exe $_.Name -pw $PW -l $username "ln -s /vmfs/volumes/$($datastore.name)/$selection2 /productLocker"
        }

        write-host ""
        write-host "Remote SSH Commands complete" -ForegroundColor Green
        write-host ""

        # Turn off SSH on hosts where SSH wasn't already enabled
        $VMhosts | foreach { 
            if ($SSHON -notcontains $_.name) {
                Write-host "Turning off SSH for $($_.Name)." -ForegroundColor Yellow
                Stop-VMHostService -HostService ($_ | Get-VMHostService | ?{ $_.Key -eq “TSM-SSH”} ) -Confirm:$false
            } else {
                Write-host "$($_.Name) already had SSH on before running the script. leaving SSH running on host..." -ForegroundColor Yellow
            }
        } 
    }
    "1" { 
        Write-Host "By not choosing `"Yes`" you will need to restart all your ESXi Hosts to have the symlink update and point to the new shared product locker location." -ForegroundColor Yellow
    }

}
Write-host ""
Write-Host "*******************
  Script Complete
*******************" -ForegroundColor Green