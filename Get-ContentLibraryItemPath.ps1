


  
  function get-ContentLibraryItemPath {
  <#
    .NOTES
    ===========================================================================
	 Created by:   	Brian Graf
     Date:          4/13/2017
	 Organization: 	VMware
     Blog:          http://www.BrianJGraf.com
     Twitter:       @vBrianGraf
     Github:        https://github.com/vtagion
	===========================================================================

	.SYNOPSIS
		Cmdlet to return the folder path of your content library item
	
	.DESCRIPTION
	    Content Library adds additional strings to the actual filenames that are uploaded to Content Library
        When looking in the UI or through the Get-ContentLibraryItem cmdlet, you see the original file name
        but not what is actually on the datastore. For those who want to mount an ISO from Content Library 
        via PowerCLI, this will take care of the heavy lifting (This is also even more useful when Content
        Library is sitting on a vSAN datastore)

	.EXAMPLE
		PS C:\> $Items = Get-ContentLibraryItem
                $ISOPATH = $Items[4] | Get-ContentLibraryItemPath
                Get-vm Win2012 | Get-CDDrive | Set-CDDrive -IsoPath $ISOPATH -StartConnected:$true -Connected:$True -Confirm:$false
#>
  param (
        [parameter(ValueFromPipelineByPropertyName)]$Name,
        [parameter(ValueFromPipelineByPropertyName)]$ItemType, 
        [parameter(ValueFromPipelineByPropertyName)]$ContentLibrary
    )
    begin {
        $Datastore = Get-datastore "vsanDatastore"

        #Get datastore view using id
        $DSView = Get-View $Datastore.id

        $Spec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
        $Browser = get-view $DSView.browser
        $DSName = ("[" + $Datastore.name +"]")
        $search = $Browser.SearchDatastoreSubFolders($DSName, $Spec)
    }
    Process{
        foreach ($Dir in $search)
        {
           
            $ISOFile = $null

            $DSFolder = (($Dir.FolderPath.Split("]").trimstart())[1]).trimend('/') 
            #$ISOFile = ($Dir.file | where {$_.Path -like "$Name*.iso"}).Path
            $ISOFile = ($Dir.file | where {$_.Path -like "$Name*.$itemtype"}).Path
            
            if ($Isofile -ne $null) { 
                $ISOpath = "[$($Datastore.name)] $DSFolder/$ISOFile"
                $ISOpath
            }
        }

    }
    end {}
  }


  $items = Get-ContentLibraryItem
  $items[4] | get-ContentLibraryItemPath

