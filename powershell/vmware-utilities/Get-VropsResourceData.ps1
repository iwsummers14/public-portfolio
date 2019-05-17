function Get-VropsResourceData() {

    <#
        .SYNOPSIS
            Gets vROM objects of the specified type and returns to caller.

        .DESCRIPTION
            The purpose of this script is to get resource objects from the specified vRealize Operations Manager and return them to the caller.

        .PARAMETER VcenterServerObj
            Object representing a connected Vcenter Server.

        .PARAMETER VropsServerObj
            Object representing a connected vRealize Operations Manager.

        .PARAMETER ResourceKind
            String, Validated set. Used to filter the Resources by type. Corresponds to an OMResource ResourceKind property.

        .PARAMETER ResourceName
            String, can be used to select only resources that match the specified name.

        .EXAMPLE
            $Clusters = Get-VropsResourceData -ResourceKind ClusterComputeResource -VcenterServerObj $connectedVC -VropsServerObj $ConnectedOM

        .OUTPUTS
            Returns object containing VroPS resource data based on requested type.

        .NOTES
            Original Author:    Ian Summers

    #>

    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true)]
        [psobject]$VcenterServerObj,
        [parameter(mandatory = $true)]
        [psobject]$VropsServerObj,
        [parameter(mandatory = $true)]
        [ValidateSet("ClusterComputeResource","Datastore","HostSystem")]
        [string]$ResourceKind,
        [parameter(mandatory = $false)]
        [string]$ResourceName


    )

    try {
        Write-Verbose "Trimming the Vcenter FQDN to get the shortname, used to identify the Adapter ID in Vrops"
        $VcenterShortName = $VcenterServerObj.Name.Split(".")[0]
        Write-Verbose "Vcenter short name: $VcenterShortName"

        if ($ResourceName){

                $VropsResources = Get-OMResource -Server $VropsServerObj -ResourceKind $ResourceKind -Name $ResourceName -ErrorAction Stop

        }

        else{

            Write-Verbose "No resource name specified. Getting filter value for Vcenter Adapter ID."
            $VcenterAdapterID = Get-OMResource -Server $VropsServerObj -ResourceKind "VMWareAdapter Instance" -ErrorAction Stop | Where-Object {$_.Name -like "$VcenterShortName*"} | Foreach-Object {$_.AdapterInstanceId}
            Write-Verbose "Vcenter Adapter ID is: $VcenterAdapterID"

            if ($ResourceKind -eq "Datastore") {
                $VropsResources = Get-OMResource -Server $VropsServerObj -ResourceKind $ResourceKind -ErrorAction Stop | Where-Object {$_.AdapterInstanceId -eq $VcenterAdapterID -and $_.Name -notlike "*-service-*"}

            }
            else {
                Write-Verbose "Collecting Vrops resources."
                $VropsResources = Get-OMResource -Server $VropsServerObj -ResourceKind $ResourceKind -ErrorAction Stop | Where-Object {$_.AdapterInstanceId -eq $VcenterAdapterID}

            }

            if ($VropsResources.Count -eq 0) {

                Write-Verbose "Filtering based on Vcenter Adapter ID yielded no clusters. Getting all resources of type $ResourceKind from vROM."
                if ($ResourceKind -eq "Datastore") {
                    $VropsResources = Get-OMResource -Server $VropsServerObj -ResourceKind $ResourceKind -errorAction Stop | Where-Object {$_.Name -notlike "*-service-*"}
                }
                else {
                    $VropsResources = Get-OMResource -Server $VropsServerObj -ResourceKind $ResourceKind -errorAction Stop
                }

                Write-Verbose "This will slow down processing as additional data will be collected. Total resources returned: $($VropsResources.Count)"

            }

        }

    }

    catch {
        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Getting Vrops resources failed, exception below."
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"


    }

    Write-Verbose "Returning Vrops resources from function $($PSCmdlet.MyInvocation.MyCommand.Name)"
    return $VropsResources

}#end function