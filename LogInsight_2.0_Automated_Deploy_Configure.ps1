<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2014 v4.1.57
	 Created on:   	7/5/2014 12:37 PM
	 Created by:   	Brian Graf - Technical Marketing Engineer - Automation
	 Organization: 	VMware
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
##############################
###### DEFINE VARIABLES ######
##############################

#vCenter
$DefaultVIServer = "192.168.1.10"
$VCuser = "root"
$VCPass = "VMw@re123"

#Virtual Machine
$TempDir = "C:\Temp\"
$vmname = "SDDC-LogInsight"
$cluster = "TM-CL"
$datastore = ""
$vmnetwork = "VM Network"
$ipadx = "192.168.1.125"
$netmask = "255.255.255.0"
$defaultgw = "192.168.1.1"
$dnsserver = "192.168.1.3"
$binary = ($TempDir + "VMware-vCenter-Log-Insight-2.0.3-1879692_1.ova")
$LIPassword = "VMw@re123"

#Log Insight Settings
$NTP = "192.168.1.3"
$AdminEmail = "vtagion@gmail.com"
$SMTPServer = "127.0.0.1"
$vCOPsIP1 = "192.168.1.25"
$vCOpsAdminPass = "VMw@re123"
$LILicenseKey = ""


##############################

Function Configure_Log_Insight_script {
	$LIPwdHash = LIEncryptString "$VCPass"
	Write-Host "vCenter Password Hash is $LIPwdHash"
	$vCOpsPwdHash = LIEncryptString "$vCOpsAdminPass"
	Write-Host "vCOps Password Hash is $vCOpsPwdHash"
	
	$VC_LI_Script = @"
#!/bin/bash
# Original Script by William Lam
# www.virtuallyghetto.com
# Modified by Brian Graf - VMware
# www.vtagion.com

# Password cannot contain any dictionary word or it will fail
LOG_INSIGHT_ADMIN_PASSWORD=VMw@re123
LOG_INSIGHT_DB_PASSWORD=VMw@re123
NTP_SERVERS="$NTP"

### DO NOT EDIT BEYOND HERE ###

LOG_INSIGHT_CONFIG_DIR=/storage/core/loginsight/config
NODE_TOKEN_FILE=node-token
LOG_INSIGHT_CONFIG_FILE=loginsight-config.xml#1
NODE_UUID=`$(uuidgen)

echo "Creating `${LOG_INSIGHT_CONFIG_DIR} .."
[ ! -e `${LOG_INSIGHT_CONFIG_DIR} ] && mkdir -p `${LOG_INSIGHT_CONFIG_DIR}

echo "Generating Log Insight Node UUID ..."
echo `${NODE_UUID} > `${LOG_INSIGHT_CONFIG_DIR}/`${NODE_TOKEN_FILE}

echo "Generating Log Insight Configuration file ..."
cat > `${LOG_INSIGHT_CONFIG_DIR}/`${LOG_INSIGHT_CONFIG_FILE} << __LOG_INSIGHT__
<config>
<version>
<strata-version value="2.0.3-1879692" release-name="2.0 GA"/>
</version>
<distributed overwrite-children="true">
<daemon port="16520" token="`${NODE_UUID}">
<service-group name="standalone"/>
</daemon>
</distributed>
<database>
<password value="`${LOG_INSIGHT_DB_PASSWORD}"/>
<port value="12543"/>
</database>
<ntp>
<ntp-servers value="`${NTP_SERVERS}"/>
</ntp>
<alerts>
<admin-alert-receivers value="$AdminEmail"/>
</alerts>
<phone-home>
<send-feedback enabled="false"/>
</phone-home>
<smtp>
<Server value="$SMTPServer"/>
</smtp>
<vsphere>
<host value="$DefaultVIServer">
<enabled value="true"/>
<username value="root"/>
<password value="$LIPwdHash"/>
<syslog-protocol value="udp"/>
<syslog-target value=""/>
<esxi-hosts-were-configured value="true"/>
</host>
</vsphere>
<vcops>
<enabled value="true"/>
<location value="$vCOPsIP1"/>
<username value="admin"/>
<password value="$vCOpsPwdHash"/>
</vcops>
</config>
__LOG_INSIGHT__

echo "inserting license key ..."		
echo $LILicenseKey > /usr/lib/loginsight/application/etc/license/loginsight_license.txt
	
echo "Restarting Log Insight ..."
service loginsight restart
sleep 60
echo "Setting Admin password ..."
ADMINPASSWORD=`${LOG_INSIGHT_ADMIN_PASSWORD} /opt/vmware/bin/li-reset-admin-passwd.sh
	
"@
	$VC_LI_Script_Clean = $VC_LI_Script -replace "`r`n", "`n"
	$VC_LI_Script_Clean | Out-File -FilePath ($Tempdir + "\LogInsight.sh") -Encoding UTF8 -Force
}

Function LIEncryptString {
	<# 
	.SYNOPSIS 
    This script encrypts then decrypts a string using AES 
	.DESCRIPTION 
    This script re-implements an MSDN sample that first  
    encrypts a string then decrypts it. The cryptography is done 
    in this case, using AES. 
	
	This allows us to create the encrypted Password string that Log Insight uses for connecting to a vCenter
	which allows Log Insight to Configure vCenter log analysis without configuring via the web GUI
	
	.In large part taken from:
    File Name  : Get-AesEnctyptedString.ps1 
    Original Author: Thomas Lee - tfl@psp.co.uk 
	Modified: 6/16/2014 - Ben Sier
	#>
	param ([string] $inString)
	# Generate CSP, Key
	$AesCSP = New-Object System.Security.Cryptography.AesCryptoServiceProvider
	# This key is hard coded for LogInsight, vCenter and vCOps password encryption for the config file(s)
	$AesCSP.Key = [System.Text.Encoding]::UTF8.GetBytes("PatternInsightCo")
	$AesCSP.Mode = [System.Security.Cryptography.CipherMode]::ECB
	# In LogInsight this was PKCS5 but padding method is the same
	$AesCSP.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
	# Convert Input to Bytes
	$inBlock = [System.Text.Encoding]::UTF8.getbytes($instring)
	$xfrm = $AesCSP.CreateEncryptor()
	$outBlock = $xfrm.TransformFinalBlock($inBlock, 0, $inBlock.Length);
	return [System.Convert]::ToBase64String($outBlock);
}

Function Import-VAppAdvanced {
	##
	# Function written by:
	# vElemental
	# @clintonskitson
	#
	##
	
	[CmdletBinding()]
	param (
		$Name,
		$ovfPath,
		$StorageFormat = "Thin",
		$Datastore = $(throw "missing -Datastore"),
		$VmHost = $(throw "missing -VmHost"),
		$Net = $(throw "missing -Net"),
		[hashtable]$hashProp
	)
	Begin
	{
		Function Get-FullPath
		{
			[CmdletBinding()]
			param ($item)
			Process
			{
				do
				{
					$parent = $item | %{ $_.parent }
					$parent | select *,@{ n = "name"; e = { (Get-View -id "$($_.type)-$($_.value)").name } }
					if ($parent)
					{
						$parent | %{
							Get-FullPath (Get-View -id "$($_.type)-$($_.value)")
						}
					}
					$parent = $null
				}
				until (!$parent)
			}
		}
	}
	Process
	{
		
		Write-Host "$(Get-Date): Checking for multiple VCs"
		if ($global:DefaultVIServers.count -gt 1)
		{
			Throw "You are connected to more than one VC, reopen PowerCLI connecting to only one vCenter instance."
		}
		
		if (!(Test-Path 'C:\Program Files\VMware\VMware OVF Tool\ovftool.exe')) { Write-Error "OvfTool 64-bit not installed"; pause; break }
		
		$vcip = $global:DefaultVIServer.name
		$vcreverseName = [System.Net.Dns]::GetHostEntry($vcip).HostName
			
		[array]$arrDatastore = Get-VMHost -id $VMhost.id | Get-Datastore | %{ $_.Id }
		if ($arrDatastore -notcontains $Datastore.Id) { Throw "Datastore $($Datastore.Name) is not connected to $($VmHost.Name)" }
		
		$NetworkName = $Net.Split("=")[-1].Replace('"', '')
		[array]$arrPortGroup = Get-VMHost -id $VMHost.id | Get-VirtualPortGroup | %{ $_.Name }
		if ($arrPortGroup -notcontains $NetworkName) { Throw "Networkname $($NetworkName) is not available on $($VmHost.Name)" }
		
		
		[array]$arrFullPath = Get-FullPath ($VmHost.Extensiondata)
		$Datacenter = $arrFullPath | where { $_.Type -eq "Datacenter" } | %{ $_.Name }
		$Cluster = $arrFullPath | where { $_.Type -eq "ClusterComputeResource" } | %{ $_.Name }
		
		
		if ($Cluster)
		{
			$viPath = "vi://$($vcip)/$Datacenter/host/$($Cluster)/$($VmHost.Name)"
		}
		else
		{
			$viPath = "vi://$($vcip)/$Datacenter/host/$($VmHost.Name)"
		}
		
		$Session = Get-View -id SessionManager
		$Ticket = $Session.AcquireCloneTicket()
		
		if ($hashProp.keys)
		{
			[string]$strProp = ($hashProp.keys | %{
				$propName = $_
				$propValue = $hashProp.$_
				"--prop:$($propName)='$($propValue)'"
			}) -join " "
		}
		
		$command = "& 'C:\Program Files\VMware\VMware OVF Tool\ovftool.exe' --I:targetSessionTicket=$Ticket --acceptAllEulas --allowExtraConfig --diskMode=`"$StorageFormat`" --datastore=`"$($Datastore.Name)`" --name=`"$($Name)`" --noSSLVerify --net:$($net) $strProp `"$OvfPath`" `"$($viPath)`""
		Write-Verbose $command
		Write-Host "$(Get-Date): Uploading OVF"
		Write-Host "$(Get-Date): Command = $($command)"
		try
		{
			$Output = Invoke-Expression $command
			
			if ($LASTEXITCODE -ne 0)
			{
				Write-Error "$(Get-Date): Problem during OVF Upload"
				Throw $Output
			}
			else
			{
				Write-Host "$(Get-Date): Successfully uploaded OVF as $($name)"
			}
		}
		catch
		{
			Write-Error "Problem uploading OVF"
			Throw $_
		}
	}
}


if (!(Test-Path 'C:\Program Files\VMware\VMware OVF Tool\ovftool.exe')) { Write-Error "OvfTool 3+ 64-bit not installed"; pause; break }

# Create LogInsight.sh
Configure_Log_Insight_script

# Run Log Insight Installer
	# Check for Snapin
	if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction 'SilentlyContinue'))
	{
		Write-Host "[INFO] Adding PowerCLI Snapin"
		add-pssnapin VMware.VimAutomation.Core -ErrorAction 'SilentlyContinue'
		if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction 'SilentlyContinue'))
		{
			Write-Host "[ERROR] PowerCLI Not installed, please install from Http://VMware.com/go/PowerCLI"
		}
		Else
		{
			Write-Host "[INFO] PowerCLI Snapin added"
		}
		connect-viserver "$DefaultVIServer" -user "$vcuser" -password "$vcpass" -WarningAction SilentlyContinue
	}
	
	Write-Host "Snapin section completed"
		
	#Select Host to use to deploy
	Write-Host "[INFO] Selecting host for $($vmname) from cluster $($cluster)"
	$myhost = Get-Cluster $cluster | Get-VMHost | Where { $_.PowerState -eq "PoweredOn" -and $_.ConnectionState -eq "Connected" } | Get-Random
	Write-Host "myhost = $myhost"

	#Select Datastore to use
	if ($datastore -eq "")
	{
		Write-Host "[INFO] Selecting Datastore for $($vmname)"
		$datastore = $myhost | Get-Datastore | Where { $_.FreeSpaceGB -ge 10 } | Get-Random
	}
	Write-Host "[INFO] Datastore $($datastore) selected for $($vmname)"

	# Set Network variable for ImportvAppAdvanced Function
	$net = '"Network 1"="' + $vmnetwork + '"'
	
	# Import OVA
	Write-Host "[INFO] Importing $($vmname) from $($binary)"
	
	Import-VAppAdvanced -Name ($vmname) -OvfPath "$($binary)" -Net ($net) -Datastore ($datastore) -VmHost ($myhost) –hashProp @{
		"vami.DNS.VMware_vCenter_Log_Insight" = "$dnsserver";
		"vami.gateway.VMware_vCenter_Log_Insight" = "$defaultgw";
		"vami.hostname.VMware_vCenter_Log_Insight" = "$vmname";
		"vami.ip0.VMware_vCenter_Log_Insight" = "$ipadx";
		"vami.netmask0.VMware_vCenter_Log_Insight" = "$netmask";
		"vm.rootpw" = "VMw@re123";
		"vm.vmname" = "$vmname";
	}
	Write-Host "[INFO] VM $($vmname) deployed"
	
	Write-Host "[INFO] Powering on $($vmname)"
	Start-VM -vm $vmname -RunAsync

Write-Host "[INFO] Sleeping 10 minutes to ensure complete load"
$i = 0
$min = 10
do {
	Write-Host "$min minutes left"
	Start-Sleep -Seconds 60
	$min = $min - 1
	$i ++
}
until ($i -eq 10)

# Copy script to Log Insight
Write-Host "[CONFIGURE] Copying LogInsight.sh to LogInsight VM"
Copy-VMGuestFile -Source ($TempDir + "\LogInsight.sh") -Destination "/storage/core/loginsight/config/LogInsight.sh" -LocalToGuest -VM "$vmname" -GuestUser root -GuestPassword "$LIPassword" -force

	Write-Host "[CONFIGURE] Copy Complete"

# Run CHMOD
	$chmod = "chmod +x /storage/core/loginsight/config/LogInsight.sh"
	Write-Host "[CONFIGURE] Running CHMOD on LogInsight.sh"
	Invoke-VMScript -vm "$vmname" -GuestUser root -GuestPassword "$LIPassword" -ScriptType Bash -ScriptText $chmod | out-null
# Run Script
	Write-Host "[CONFIGURE] Running LogInsight.sh (This will take approximately 90 seconds)"
	Invoke-VMScript -VM "$vmname" -GuestUser root -GuestPassword "$LIPassword" -ScriptType Bash -ScriptText "/storage/core/loginsight/config/LogInsight.sh" | out-null
# If License file is empty, remove it
	if ($license -eq "")
	{
		$script = "rm /usr/lib/loginsight/application/etc/license/loginsight_license.txt"
		Invoke-VMScript -VM "$vmname" -GuestUser root -GuestPassword "$LIPassword" -ScriptType Bash -ScriptText $script | out-null
	}

	Write-Host "[CONFIGURE] Script Complete"
	Write-Host ""
	
