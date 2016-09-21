<#	
	.NOTES
	===========================================================================
	 Created on:   	9/21/2016 12:17 PM
	 Created by:   	 Brian Graf
	 Organization: 	VMware
	 Twitter:     	@vBrianGraf
	 Blog:			www.vtagion.com
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>
<#
	.SYNOPSIS
		Return all Product Data from deployed VM's/OVAs in vCenter
	
	.DESCRIPTION
		This will return the Product Name, Version, Product URL, and ApplianceUrl if they are listed in the VM Product properties
	
	.EXAMPLE
				PS C:\> Get-DeployedProduct
	.EXAMPLE
				PS C:\> Get-DeployedProdcut | Export-Csv  -Path c:\temp\deployedproducts.csv -NoTypeInformation
	
	.NOTES
		Additional information about the function.
#>
function Get-DeployedProduct
{
	[CmdletBinding()]
	param ()
	Begin {$VMs = Get-VM * | where { $_.ExtensionData.Summary.Config.Product.Name -ne $null } }
	Process
	{
		$Products = @()
		foreach ($VM in $VMs)
		{
			$Properties = [ordered]@{
				'VMName' = $VM.name;
				'ProductName' = $VM.extensiondata.summary.config.product.name;
				'Version' = $VM.extensiondata.summary.config.product.version;
				'FullVersion' = $VM.extensiondata.summary.config.product.fullversion;
				'ProductURL' = $VM.extensiondata.summary.config.product.producturl;
				'AppURL' = $VM.extensiondata.summary.config.product.appurl
			}
			$obj = New-Object PSObject -Property $Properties 
			$Products += $obj
		}
	}
	End { return $Products }
}

