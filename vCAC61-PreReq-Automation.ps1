﻿
#==============================================
# Generated On: 9/8/2014 1:13 PM
# Generated By: Brian Graf
# Technical Marketing Engineer - Automation
# Organization: VMware
# Twitter: @vTagion
# VCAC 6.1 Pre-Req Automation Script v1
#==============================================
#----------------------------------------------
#==================USAGE=======================
# For Windows Server 2008 & 2012
# This script has been created to aid in 
# Configuring the settings for the vCAC 6.1
# Pre-Req Checker. This script will set all
# Pre-Req's except for enabling TCP/IP in 
# MS SQL, chich needs to be performed manually
# And the services will need to be restarted.
#----------------------------------------------
#===============REQUIREMENTS===================
# For this script to run successfully be sure:
# 	*To run PowerShell as administrator
#	*To have admin rights on the server
#----------------------------------------------

#=============EDITOR'S NOTE====================
# In order for this script to work on servers that
# have proxied or restricted access to the Internet,
# it is necessary to configure a local source repository
# or else the features and roles requiring .NET 3.5 will fail.
# To do so, configure the variable called $InstallSource
# below making sure to set the path appropriately. In
# this example, the source is provided by mounting the
# installation CD as drive D.
# 	- Chip Zoller, Senior Virtualization Engineer, Worldpay US 

# ----------------------------------------
#   USER CONFIGURATION - EDIT AS NEEDED
# ----------------------------------------

# Set IIS default locations to be used with IIS role
$InetPubRoot = "C:\Inetpub"	
$InetPubLog = "C:\Inetpub\Log"	
$InetPubWWWRoot = "C:\Inetpub\WWWRoot"

# Specify what the installer will do if .NET is not 4.5.1
# 1 - use a local .NET installer, 2 - Auto-Download from the internet and proceed , 3 - Exit the script
$menuoption = ""
$dotnetlocalpath = ""

# ------------- Server 2012 ---------------
# Specify what the installer will do for installing framework components
# 1 - use a local 2012 iso sources folder, 2 - Auto-Download from Microsoft servers internet and proceed , 3 - Exit the script
$frameworkmenuoption = ""
# Set install source location if unable to directly connect to the Internet
# Example of Mounted 2012 ISO source path (ex D:\sources\sxs)
$InstallSource = ""
# This applies ONLY to 2012

#Specify how you would like to obtain and run NTRights.exe
# 1 - use a local NTRights.exe file , 2 - Auto-Download from the internet and proceed , 3 - Exit the script
$NTRightsmenuoption = ""
#Example C:\Temp\NTRights.exe
$NTRightsInstallSource = ""
#Account to use for Batch Logon and Secondary Logon Services (if left blank will default to local administrators group)
# Example Corp\vcacservice or Eng\Smithj
$domainAdminAcct = ""

# Specify what the installer will do if Java is not 1.7
# 1 - use a local Java installer, 2 - Auto-Download from the internet and proceed , 3 - Exit the script
$javamenuoption = ""
$javalocalpath = ""

# ----------------------------------------
# 		END OF USER CONFIGURATION 
# ----------------------------------------

# ----Do not modify beyond this point-----
$ErrorActionPreference="SilentlyContinue"
$ErrorActionPreference="Continue"

# ----------------------------------------
# 		CHECK POWERSHELL SESSION 
# ----------------------------------------
$Elevated = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
& {
    if ($Elevated.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))
    {
 
        write-host "PowerShell is running as an administrator." -ForegroundColor Green 
    } Else {
		throw "Powershell must be run as an adminstrator."
	}
	
    if( [IntPtr]::size * 8 -eq 64 )
    {
		Write-Host "You are running 64-bit PowerShell" -ForegroundColor Green 
        
    }
    else
    {
		Write-Host "You are running 32-bit PowerShell" -ForegroundColor Red 
		Throw "Please run using 64-bit PowerShell as administrator" 
    }
}
# ----------------------------------------
# 		END OF POWERSHELL CHECK
# ----------------------------------------


# ----------------------------------------
# 		CHECK FOR .NET FRAMEWORK
# ----------------------------------------

# .NET FRAMEWORK 4.5.1 is required for vCAC 6.1 to run properly 
	# Check to see if .Net 4.5.1 is present
	$DNVersion = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -name Version -EA 0 | Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} | Sort-Object version -Descending | Select-Object -ExpandProperty Version -First 1
	$DNVersions = $DNVersion.Split(".")
	$DNVersionMajor = $DNVersions[0]
	$DNVersionMinor = $DNVersions[1]
	$DNVersionBuild = $DNVersions[2]
	
	
	# If .Net is older than 4.5, stop installer until .Net is upgraded
	if ($DNVersionMajor -eq 4 -and $DNVersionMinor -eq 5 -and $DNVersionBuild -ge 1 ){ Write-Host ".NET version on this server is $DNVersion "	-ForegroundColor Green
	}else{
	 	Write-Host "vCAC 6.1 requires .Net framework version 4.5.1 to continue" -ForegroundColor Red
		if ($menuoption -eq ""){
		do{
			Write-Host "
	(1) - I have the .Net 4.5.1 installer and want to install it from a local folder
	(2) - I have internet access and want to download and install it automatically
	(3) - Exit this script" -ForegroundColor Yellow
			$menuoption = read-Host -Prompt "Choose a number to proceed:  "
		} Until ($menuoption -eq "1" -or $menuoption -eq "2" -or $menuoption -eq "3")}
			Switch ($menuoption){
			"1" {
					do {
						$dotnetlocalpath = Read-Host -Prompt "Unable to locate file. Where is the .NET 4.5.1 installer located locally? (example c:\temp\dotnetinstaller.exe)"
					} Until ((Test-path -Path $dotnetlocalpath -ErrorAction SilentlyContinue) -eq $true)
					Write-Host "Attempting to Install .NET 4.5.1. Please be patient." -ForegroundColor Green
					Write-Verbose ""
					$InstallDotNet = Start-Process $dotnetlocalpath -ArgumentList "/q /norestart" -Wait -PassThru
					Write-Host "Dot Net Installation finished. Proceeding with Server configuration." -ForegroundColor Green
				
					}
			"2" {
				if (!(test-path -Path "c:\Temp")){
					Write-Host "Creating folder C:\Temp" -ForegroundColor Green
					New-Item -ItemType Directory -Force -Path "C:\Temp"
				}
				Write-Host "Preparing to Download .NET 4.5.1" -ForegroundColor Green
				Write-Host "Attempting to Download .NET 4.5.1. Please be patient." -ForegroundColor Green
					$download = New-Object Net.WebClient
					$url = "http://download.microsoft.com/download/1/6/7/167F0D79-9317-48AE-AEDB-17120579F8E2/NDP451-KB2858728-x86-x64-AllOS-ENU.exe"
					$file = ("C:\Temp\DotNet451.exe")
					$download.Downloadfile($url,$file)
				if (!(Test-Path -Path "C:\Temp\DotNet451.exe")) {Write-Host "Uh Oh. For some reason we were unable to download the .NET Installer correctly" -ForegroundColor Yellow
				Throw "Please check your internet connection and rerun this script" } else {Write-Host "File downloaded successfully... Proceeding" -ForegroundColor Green}
				Write-Host "Attempting to Install .NET 4.5.1. Please be patient." -ForegroundColor Green
				Write-Verbose ""
				$InstallDotNet = Start-Process $file -ArgumentList "/q /norestart" -Wait -PassThru
				Write-Host "Dot Net Installation finished. Proceeding with Server configuration." -ForegroundColor Green
				
			}
			"3" { Exit }
			}
#		}
	}

# ---------------------------------------
#       END OF .NET FRAMEWORK CHECK
# ---------------------------------------

# ---------------------------------------
#      Check Operating System Version
# ---------------------------------------

# Grab the OS Name
$os = (get-WMiObject -class Win32_OperatingSystem).caption

# Overwrite $OS variable with smaller string
switch -wildcard ($os) {
"*2008*" {
	Write-Host "OS = $os" -ForegroundColor Green
	$os = "2008"
}
"*2012*" {
	Write-Host "OS = $os" -ForegroundColor Green
	$os = "2012"
}
Default {Write-Host "The current operating system, $os, is not supported at this time" }
}

# ---------------------------------------
#       END OF OS VERSION CHECK
# ---------------------------------------


# Begin installations

# ----------------------------------------
# 	  BEGIN ROLE AND FEATURE INSTALL 
# ----------------------------------------


# Loading feature installation modules	
Write-Host "Importing Server Manager " -ForegroundColor Yellow
Import-Module ServerManager 

Write-Host "Installing IIS roles " -ForegroundColor Yellow
if ($os -eq "2008") {
# Installing roles specified in vCAC 6 Pre-req checker
Add-WindowsFeature -Name Web-Webserver,Web-Http-Redirect,Web-Asp-Net,Web-Windows-Auth,Web-Mgmt-Console,Web-Mgmt-Compat, web-metabase
}

if ($os -eq "2012"){

if ($frameworkmenuoption -eq ""){
		do{
			Write-Host "
	(1) - I have the Server 2012 ISO mounted and want to install the framework files from a local folder
	(2) - I have internet access and want to download it from Microsoft and install it automatically
	(3) - Exit this script" -ForegroundColor Yellow
			$frameworkmenuoption = read-Host -Prompt "Choose a number to proceed:  "
		} Until ($frameworkmenuoption -eq "1" -or $frameworkmenuoption -eq "2" -or $frameworkmenuoption -eq "3")}
			Switch ($frameworkmenuoption){
			"1" {
					do {
						$InstallSource = Read-Host -Prompt "Unable to locate folder. Please specify the source folder for required files (ex D:\sources\sxs\)"
					} Until ((Test-path -Path $InstallSource -ErrorAction SilentlyContinue) -eq $true)
					Write-Host "Attempting to Install .NET Framework. Please be patient." -ForegroundColor Green
					Add-WindowsFeature -Name Web-Webserver,Web-Http-Redirect,Web-Asp-Net,Web-Windows-Auth,Web-Mgmt-Console,Web-Mgmt-Compat, web-metabase -Source $InstallSource
				
					}
			"2" {	
				# Disable Proxy config on Internet Explorer
				set-itemproperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -name ProxyEnable -value 0
				#
				Write-Host "Preparing to Download Framework Components" -ForegroundColor Green
				Write-Host "Attempting to Download Framework Components. Please be patient. (~200MB)" -ForegroundColor Green
				if (Test-Connection google.com -Count 3 -ErrorAction SilentlyContinue) {Write-Host "Internet Connection Succeeded." -ForegroundColor Green}
					Add-WindowsFeature -Name Web-Webserver,Web-Http-Redirect,Web-Asp-Net,Web-Windows-Auth,Web-Mgmt-Console,Web-Mgmt-Compat, web-metabase
				Write-Host "Framework finished. Proceeding with Server configuration." -ForegroundColor Green
								
			}
			"3" { Exit }
			}
#		}
} 

Write-Host "IIS role installation complete, adding features... "  -ForegroundColor Green

# ---------------------------------------
#      Install Correct Framework
# ---------------------------------------
# Run the correct command based off the OS result
switch ($os) {
"2008" {
	# Adding 2008 features specified in vCAC 6 Pre-req checker
	Write-Host "Adding Windows features " -ForegroundColor Yellow
	Add-WindowsFeature -Name AS-Net-framework, NET-Win-CFAC, NET-HTTP-Activation, NET-Non-HTTP-Activ
	Write-Host "Features installation complete, loading IIS module "  -ForegroundColor Green
}
"2012" {
	
	# Adding 2012 features specified in vCAC 6 Pre-req checker
	Write-Host "Adding Windows features " -ForegroundColor Yellow
	Install-WindowsFeature -name NET-Framework-Core,net-wcf-http-activation45
	Add-windowsfeature -name was, was-config-apis, was-Net-Environment,NET-Non-HTTP-Activ
	Write-Host "Features installation complete, loading IIS module "  -ForegroundColor Green}

Default {Write-Host "The Operating System does not appear to be compatible with this script"
Throw "This is for Windows Server 2008 and 2012"
}
}
# ---------------------------------------
#       END OF Framework Installation
# ---------------------------------------


# Loading IIS web admin module	
if (Get-Module -ListAvailable WebAdministration){
	Write-host "Importing Web Admin module " -Foregroundcolor Yellow    
    Import-Module WebAdministration
}
else {

    throw "Webadministration is not installed on this system" 
}

# Build the IIS folder structure	
Write-Host "Setting up folder structure"  -ForegroundColor Yellow
New-Item -Path $InetPubRoot -type directory -Force -ErrorAction SilentlyContinue	
New-Item -Path $InetPubLog -type directory -Force -ErrorAction SilentlyContinue	
New-Item -Path $InetPubWWWRoot -type directory -Force -ErrorAction SilentlyContinue
	
# Set the directory access for 'Builtin\IIS_IUSRS' and 'NT SERVICE\TrustedInstaller'
$Command = "icacls $InetPubWWWRoot /grant BUILTIN\IIS_IUSRS:(OI)(CI)(RX) BUILTIN\Users:(OI)(CI)(RX)"
cmd.exe /c $Command
$Command = "icacls $InetPubLog /grant ""NT SERVICE\TrustedInstaller"":(OI)(CI)(F)"
cmd.exe /c $Command
	
# Setting the default website location used in vCAC	
Set-ItemProperty 'IIS:\Sites\Default Web Site' -name physicalPath -value $InetPubWWWRoot	

# Setting authentication values for IIS
# Anonymous Authentication needs to be disabled
# Windows Authentication needs to be enabled
Write-Host "Setting authentication values for IIS" -ForegroundColor Yellow
Set-WebConfigurationProperty -Location 'Default Web Site' -Filter /system.webServer/security/authentication/AnonymousAuthentication  -Name Enabled -Value $true
Set-WebConfigurationProperty -Location 'Default Web Site' -Filter /system.webServer/security/authentication/AnonymousAuthentication  -Name Enabled -Value $false

Set-WebConfigurationProperty -Location 'Default Web Site' -Filter /system.webServer/security/authentication/windowsAuthentication  -Name Enabled -Value $false
Set-WebConfigurationProperty -Location 'Default Web Site' -Filter /system.webServer/security/authentication/windowsAuthentication  -Name Enabled -Value $true

# Sometimes the pre-req checker cannot distinguish the values of the Windows authentication without
# The providers being removed and added back in.
# Removing and re-adding Windows authentication providers

Write-Host "Removing & Re-Adding Windows authentication providers" -ForegroundColor Yellow
# Authentication Providers code by Jonathan Medd http://www.jonathanmedd.net
Get-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name providers.Collection | Select-Object -ExpandProperty Value | ForEach-Object {Remove-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name providers.Collection -AtElement @{value=$_}}
Add-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name providers.Collection -AtIndex 0 -Value "Negotiate"
Add-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name providers.Collection -AtIndex 1 -Value "NTLM"

# Extended protection needs to be enabled and disabled for vCAC to recognize the value
# Enable and disable the Extended Protection
Write-Host "Enabling and disabling Extended Protection" -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name extendedProtection.tokenChecking -Value 'Allow'
Set-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name extendedProtection.tokenChecking -Value 'None'

# The same must happen with Kernel-Mode. This will disable then re-enable the value
# Resetting KERNEL MODE 
Write-Host "Resetting Kernel Mode" -ForegroundColor Yellow
Set-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name useKernelMode -Value $false
Set-WebConfigurationProperty -Filter system.webServer/security/authentication/WindowsAuthentication -Location 'Default Web Site' -Name useKernelMode -Value $true

# IIS must be restarted for the changes to take effect
# Resetting IIS 
Write-Host "Resetting IIS" -ForegroundColor Yellow
$Command = "IISRESET"
Invoke-Expression -Command $Command
Write-Host "IIS Reset Complete..."  -ForegroundColor Green


# ----------------------------------------
#      END OF ROLE & FEATURE INSTALL
# ----------------------------------------

# ----------------------------------------
# 	   FIREWALL & SECURITY SETTINGS 
# ----------------------------------------

# MSDTC is used for Coordinating Transactions spanning several resource managers (databases, message queues, etc)
# The following settings will allow vCAC to function properly on the network.
# Setting the MSDTC components
Write-Host "Setting MSDTC components in the registry. Please restart your system after installation completes" -ForegroundColor Yellow
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name LuTransactions -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccess -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccessInbound -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccessOutbound -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcClients -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccessTransactions -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccessAdmin -Value 1
Set-ItemProperty -Path HKLM:\Software\Microsoft\MSDTC\Security -Name NetworkDtcAccessClients -Value 1

# The Distributed Transaction Coordinator needs to have access through the firewall
# The following line of code is all that we will use. (If the firewall is enabled it
# Will utilize the rule, if the firewall is disabled, this can be ignored
# Creating firewall rule for DTC

#netsh advfirewall firewall set rule group="Distributed Transaction Coordinator" new enable=Yes | Out-Null
netsh advfirewall firewall set rule group="Distributed Transaction Coordinator" new enable=Yes

# ----------------------------------------
# 	 END FIREWALL & SECURITY SETTINGS 
# ----------------------------------------

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
	
if ($NTRightsmenuoption -eq ""){
		do{
			Write-Host "
	(1) - I have the NTRights.exe and want to run the file from a local folder
	(2) - I have internet access and want to download it from the internet automatically
	(3) - Exit this script" -ForegroundColor Yellow
			$NTRightsmenuoption = read-Host -Prompt "Choose a number to proceed:  "
		} Until ($NTRightsmenuoption -eq "1" -or $NTRightsmenuoption -eq "2" -or $NTRightsmenuoption -eq "3")}
			Switch ($NTRightsmenuoption){
			"1" {
					do {
						$NTRightsInstallSource = Read-Host -Prompt "Unable to locate file. Please specify the location of ntrights.exe(ex c:\temp\ntrights.exe)"
					} Until ((Test-path -Path $NTRightsInstallSource -ErrorAction SilentlyContinue) -eq $true)
					Write-Host "Attempting to run NTRights.exe." -ForegroundColor Yellow
					if ($domainAdminAcct -eq "") {$domainAdminAcct = read-Host -Prompt "What is the domain admin account for vCAC-IAAS? (ex. Corp\Services)  " }
					Write-Host "Account specified for Batch Logon and Secondary Service Logon is $domainAdminAcct" -ForegroundColor Yellow
					}
			"2" {
				Write-Host "Preparing to Download NTrights.exe" -ForegroundColor Green
				Write-Host "Attempting to Download NTrights.exe." -ForegroundColor Green
				if (!(test-path -Path "c:\Temp")){
					Write-Host "Creating folder C:\Temp" -ForegroundColor Green
					New-Item -ItemType Directory -Force -Path "C:\Temp"
				}
				if (Test-Connection google.com -Count 3 -ErrorAction SilentlyContinue) {Write-Host "Internet Connection Succeeded." -ForegroundColor Green}
					$downloadNTRights = New-Object Net.WebClient
					$javaurl = "http://www.jonathanmedd.net/?wpdmact=process&did=My5ob3RsaW5r"
					$javafile = ("C:\Temp\NTRights.exe")
					$downloadNTRights.Downloadfile($javaurl,$javafile)
				if (!(Test-Path -Path "C:\Temp\NTRights.exe")) {Write-Host "Uh Oh. For some reason we were unable to download NTRights.exe correctly" -ForegroundColor Yellow
				Throw "Please check your internet connection and rerun this script" } else {Write-Host "File downloaded successfully... Proceeding" -ForegroundColor Green}
				if ($domainAdminAcct -eq "") {$domainAdminAcct = read-Host -Prompt "What is the domain admin account for vCAC-IAAS? (ex. Corp\Services)  " }
				Write-Host "Account specified for Batch Logon and Secondary Service Logon is $domainAdminAcct" -ForegroundColor Yellow
				$NTRightsInstallSource = "C:\Temp\NTRights.exe"
								
			}
			"3" { Exit }
			}



	Write-Host "Setting Batch Logon Rights" -ForegroundColor Yellow
	#iex "c:\Temp\NTRights.exe +r SeBatchLogonRight -u $domainAdminAcct"
	iex "$NTRightsInstallSource +r SeBatchLogonRight -u $domainAdminAcct"
	Write-Host "Setting Secondary Logon Rights" -ForegroundColor Yellow
	#iex "c:\Temp\NTRights.exe +r SeServiceLogonRight -u $domainAdminAcct"
	iex "$NTRightsInstallSource +r SeServiceLogonRight -u $domainAdminAcct"
	
# ----------------------------------------
# 	   END LOGON SERVICE SETTINGS 
# ----------------------------------------

# All Windows settings are now set for vCAC to install correctly
# After SQL Server is installed, make sure to enable TCP/IP and
# Restart the SQL services

# ----------------------------------------
# 	     JAVA INSTALL & CONFIG 
# ----------------------------------------
Write-Host "Java Section " -ForegroundColor Yellow
if (dir "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment" -ErrorAction SilentlyContinue){
$JavaVersion = dir "HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment"  | select -expa pschildname -Last 1
$JavaVersions = $JavaVersion.Split(".")
$JavaVersionMajor = $JavaVersions[0]
$JavaVersionMinor = $JavaVersions[1]
$JavaVersionBuild = $JavaVersions[2]
} else {$javaversionmajor = 0}
# If .Net is older than 4.5, stop installer until .Net is upgraded
	if ($JavaVersionMajor -eq 1 -and $JavaVersionMinor -ge 7 ){ Write-Host "Java version on this server is $JavaVersion "	-ForegroundColor Green
	}else{
	 	Write-Host "vCAC 6.1 requires Java JRE 1.7 64-bit or higher" -ForegroundColor Red
		if ($javamenuoption -eq ""){
		do{
			Write-Host "
	(1) - I have the Java JRE 1.7 or higher and want to install it from a local folder
	(2) - I have internet access and want to download and install it automatically
	(3) - Exit this script" -ForegroundColor Yellow
			$javamenuoption = read-Host -Prompt "Choose a number to proceed:  "
		} Until ($javamenuoption -eq "1" -or $javamenuoption -eq "2" -or $javamenuoption -eq "3")}
			Switch ($javamenuoption){
			"1" {
					do {
						$javalocalpath = Read-Host -Prompt "Unable to locate file. Where is the Java installer located locally? (example c:\temp\jre71.exe)"
					} Until ((Test-path -Path $javalocalpath -ErrorAction SilentlyContinue) -eq $true)
				Write-Host "Attempting to Install Java. Please be patient." -ForegroundColor Green
				Write-Verbose ""
				$InstallJava = Start-Process $javalocalpath -ArgumentList "/s" -Wait -PassThru
				Write-Host "Java installation finished. Proceeding with script." -ForegroundColor Green
				}
			"2" {
				if (!(test-path -Path "c:\Temp")){
					Write-Host "Creating folder C:\Temp" -ForegroundColor Green
					New-Item -ItemType Directory -Force -Path "C:\Temp"
				}
				Write-Host "Preparing to Download Java JRE 1.7" -ForegroundColor Green
				Write-Host "Attempting to Download Java. Please be patient." -ForegroundColor Green
					$downloadjava = New-Object Net.WebClient
					$javaurl = "http://javadl.sun.com/webapps/download/AutoDL?BundleId=95125"
					$javafile = ("C:\Temp\javajre17.exe")
					$downloadjava.Downloadfile($javaurl,$javafile)
				if (!(Test-Path -Path "C:\Temp\javajre17.exe")) {Write-Host "Uh Oh. For some reason we were unable to download the Java installer correctly" -ForegroundColor Yellow
				Throw "Please check your internet connection and rerun this script" } else {Write-Host "File downloaded successfully... Proceeding" -ForegroundColor Green}
				Write-Host "Attempting to Install Java. Please be patient." -ForegroundColor Green
				Write-Verbose ""
				$InstallJava = Start-Process $javafile -ArgumentList "/s" -Wait -PassThru
				Write-Host "Java installation finished. Proceeding with script." -ForegroundColor Green
				
			}
			"3" { Exit }
			}
#		}
	}
	Write-Host "Setting Java_HOME variable to C:\Program Files\Java\jre7" -ForegroundColor Green
	setx /M JAVA_HOME "C:\Program Files\Java\jre7"
	Write-Host "Java_HOME variable set." -ForegroundColor Green

# ----------------------------------------
# 	   END JAVA INSTALL & CONFIG
# ----------------------------------------


Write-Host ""
Write-Host "Pre-Req settings have been completed." -foregroundcolor Green
Write-Host "Please run the prerequisite checker and verify. Proceed with SQL pre-reqs" -ForegroundColor Green

# ----------------------------------------
# 	         END OF SCRIPT 
# ----------------------------------------

