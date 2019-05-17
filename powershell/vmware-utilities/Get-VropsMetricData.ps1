function Get-VropsMetricData() {

    <#
        .SYNOPSIS
            Gets vROM metric data for the specified metrics and returns this data to caller.

        .DESCRIPTION
            The purpose of this script is to get requested metric data from the specified vRealize Operations Manager server and return them to the caller.

        .PARAMETER VcenterServerObj
            Object representing a connected vCenter Server.

        .PARAMETER VropsServerObj
            Object representing a connected vRealize Operations Manager.

        .PARAMETER Resources
            Object containing vRealize resources to target.

        .PARAMETER MetricList
            Array of metrics to pull data from.

        .EXAMPLE
            $ClusterData = Get-VropsMetricData -Resources $OMClusters -MetricList $ClusterMetrics -VcenterServerObj $connectedVC -VrOpsServerObj $connectedOM

        .OUTPUTS
            Returns object containing vROPS metric data based on requested type.

        .NOTES
            Original Author:    Ian Summers

    #>

    [CmdletBinding()]
    param
    (
        [parameter(mandatory = $true)]
        [psobject]$VcenterServerObj,
        [parameter(mandatory = $true)]
        [psobject]$VrOpsServerObj,
        [parameter(mandatory = $true)]
        [psobject]$Resources,
        [Parameter(Mandatory = $true)]
        [array]$MetricList,
        [Parameter(Mandatory = $true)]
        [datetime]$StartDate,
        [Parameter(Mandatory = $true)]
        [datetime]$EndDate


    )

try{

    Write-Verbose "Collecting vROM metric data for these parameters:"
    Write-Verbose "Resources: $($Resources.Name | format-list | out-string)"
    Write-Verbose "Requested Metrics: $($MetricList | format-list | out-string)"
    Write-Verbose "Start Date: $($StartDate | Out-string)"
    Write-Verbose "End Date: $($EndDate | Out-string)"
    Write-Verbose "Creating a results array"
    $VropsMetricData = @()

    Write-Verbose "Collecting stats from vROM"
    foreach ($Resource in $Resources){

            Write-Verbose "Collecting stats from vROM"
            Write-Verbose "Current resource: $($Resource.name)"
            $VropsMetricData += get-OMStat -Server $VrOpsServerObj -Resource $Resource -From $StartDate -IntervalType Minutes -IntervalCount 60 -rolluptype Latest -To $EndDate -Key $MetricList -ErrorAction Stop

    }


}

    catch {
        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Getting vROps metrics failed, exception below."
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"


    }

    Write-Verbose "Returning vROps resources from function $($PSCmdlet.MyInvocation.MyCommand.Name)"
    return $VropsMetricData



}#end of function