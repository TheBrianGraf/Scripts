# Data exported to a CSV:
# * Cluster (given a number to not give true cluster name)
# * Cluster Size (used to understand potential complexity of the DRS Rules)
# * Total number of DRS Rules (Just a count, no other info)
# * Total number of VMs included in the rules (Just a count, no other info)
# * Average VMs per DRS rule (just a calculation between the other two numbers)


# Must be connected to vCenter (Connect-VIServer cmdlet)
# This script does a single read-only query (Get-Cluster).
# No data is being pushed back into the environment and as
# the one cmdlet run is a Read-Only

function start-rulesQuery {

# Create an array for the objects below
$clusters = @()

# For each cluster, run the following
$i = 1
foreach ($cls in (get-cluster)) {

# Variable for the DRS Rules
$rules = $cls.ExtensionData.Configuration.Rule

# Variable for the number of DRS Rules
$numRules = $rules.count

# Variable for the total number of VMs included in DRS rules
$numVMs = $rules.vm.count

# Calculate the averate nume of VMs per DRS rule
$AVGVMsPerRule = ($numVMs / $numRules)

# Organize the output
$reporthash = [ordered]@{
CLSName = "Cluster$i"
Clustersize = $cls.ExtensionData.host.count
NumRules = $numRules
NumVMs = $numVMs
AVGVMs = $AVGVMsPerRule
}

# Create the object from the above Hashtable
$clsobject = New-object -typename psobject -Property $reporthash

# Add the object to the array first specified
$clusters += $clsobject

$i++
}

# Returns the data
return $clusters
}

# Runs the above function and exports to a CSV, Path needs to be specified
Start-rulesQuery | export-csv -Path "" -NoTypeInformation

# Please email results to grafb@vmware.com
# Thank you for your help

