# This script is used on vRA 7.2 windows IaaS hosting at least DEMO workers

#============= vRealize Automation 7.2 ==================== 
# vRA 7.2 installer has greatly improved over previous versions
# The vRA 7.2 installer has a Run, Fix step to add all pre-reqs
# I've used the script to help install pre-reqs ahead of time, make wizard installs faster
# I've used on Medium Enterprise and Minimal vRA installs
# After running this script, the only part needing fixed
# A windows firewall exception, not sure why
# On my windows machines, windows firewall is disabled
#
# I just run fix and vRA 7.2 installer wizard moves on
#
# For pre-reqs, visit
# -- https://www.vmware.com/support/pubs/vrealize-automation-pubs.html
#
# To use script
# ----------------------------
# -- Copy dotnet452.exe c:\temp
# 
# -- I've used this script on IaaS web and manager servers
# -- My vRA architecture has separate DEM / Agent machines
# -- There is a separate script for IaaS web and manager machines
# 
# -- Look on http://github.com/steveschofield for both scripts
# -- Steve Schofield - http://iislogs.com/steveschofield
# 
# End description by Steve Schofield

$dotnetlocalpath = "C:\Temp\DotNet452.exe" 
$InstallDotNet = Start-Process $dotnetlocalpath -ArgumentList "/q /norestart" -Wait -PassThru
Write-Host "Dot Net Installation finished. Proceeding with Server configuration." -ForegroundColor Green 

Write-Host "Enabling Secondary Logon Service" -ForegroundColor Yellow 
 
# ---------------------------------------- 
# 	     LOGON SERVICE SETTINGS  
# ---------------------------------------- 
 
# Enabling Secondary Logon service 
# If the 'Secondary Logon' service is not running, this will set the service to 
# Automatic and start the service 
Write-Host "Enabling Secondary Logon Service" -ForegroundColor Yellow 
 
	if ((Get-Service seclogon).Status -ne 'Running'){ 
 		Set-Service Seclogon -StartupType Automatic 
     	Start-Service seclogon 
 		Write-Host "Secondary Logon Service Enabled..."  -ForegroundColor Yellow 
 	}