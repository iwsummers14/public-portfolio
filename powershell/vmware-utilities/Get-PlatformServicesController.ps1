function Get-PlatformServicesController() {

    <#
        .SYNOPSIS
            Get the host name of the Platform Services Controller and return it.

        .DESCRIPTION
            The purpose of this script is to collect vCenter server, platform services controller, and host versions and
            return the data for a report.

        .PARAMETER VcenterServerObj
            vCenterServer that the capacity data will be collected from.

        .EXAMPLE
            $reportData = Get-VersionReportData -VcenterServerObj $connectedVC -VropsServerObj $connectedOM

        .OUTPUTS
            Returns a string value of the PSC host name for the specified vCenter.

        .NOTES
            Original Author:        Ian Summers

    #>

    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true)]
        [psobject]$VcenterServerObj

    )

    try {


        Write-Verbose "Declaring return variable"
        $ReturnData = ""

        Write-Verbose "Getting PSC information from advanced vCenter settings"
        $PscData = Get-AdvancedSetting -Entity $VcenterServerObj -Name config.vpxd.sso.admin.uri -ErrorAction Stop

        Write-Verbose "Extracting PSC host name from URL"
        $PscHostName = $PscData.Value.Split("/")[2]

        Write-Verbose "Comparing PSC host name to vCenter host name to determine if PSC is embedded"
        if ($PscHostName -eq $VcenterServerObj.Name) {

            Write-Verbose "vCenter server uses an embedded PSC"
            $ReturnData = "embedded"

        }
        else {

            Write-Verbose "PSC is external and is $PscHostName"
            $ReturnData = $PscHostName

        }

    }#end try
    catch {

            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName

            Write-Verbose "ERROR: Obtaining platform services controller for this vCenter failed."
            Write-Verbose "     Exception: $ErrorMessage"
            Write-Verbose "   Failed Item: $FailedItem"

            Write-Verbose "Setting return data to reflect error state"
            $ReturnData = "error"
    }


    return $ReturnData

}