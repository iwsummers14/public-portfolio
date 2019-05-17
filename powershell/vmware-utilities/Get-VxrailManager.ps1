function Get-VxrailManager () {

    <#
        .SYNOPSIS
            Identifies a VxRail manager for a given cluster using a regular expression.

        .DESCRIPTION
            Identifies a VxRail manager for a given cluster using a regular expression.
            Looks for the format aaa-b-ccccvx-dd, where:
                aaa  = site code - che, dae, ame, lde
                b    = production level - n, p
                cccc = cluster name (up to 4 chars)
                dd   = numeric indicator - 01, 02, etc

        .PARAMETER TargetCluster
            String - targeted cluster name

        .PARAMETER VcenterServerObj
            PSObject - object representing a connected vCenter server.

        .EXAMPLE
            $VXRailMgr = Get-VxrailManager -VcenterServerObj $ConnectedVC -TargetCluster Dev

        .OUTPUTS
            Returns a string value of the vxrail manager for the targeted cluster

        .NOTES
            Author: Ian Summers

    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [psobject]
        $VcenterServerObj,
        [Parameter(mandatory = $true)]
        [string]
        $TargetCluster

    )

    try {

        Write-Verbose "Looking up VMs that match the name pattern via regex"
        $VxrailManager = Get-Cluster -Name $TargetCluster -Server $VcenterServerObj | Get-VM | Where-Object{$_.Name -match '\w{3}-\w-\w{3,4}vx-\d{2}'} -ErrorAction Stop

        if ($VxrailManager)
        {

            Write-Verbose "$($VxrailManager.Name) was identified via regex. Returning value"
            return $VxrailManager.Name

        }
        else {
            Write-Verbose "No VXrail manager identified. Returning null"
            return $null
        }

    }

    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Getting VXRail Manager failed, exception below."
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"

        return $null

    }

}
