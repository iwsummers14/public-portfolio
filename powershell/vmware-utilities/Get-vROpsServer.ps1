function Get-VropsServer () {

    <#
        .SYNOPSIS
            Get Vrops server that has registered a plugin with a given Vcenter server.
            This returns an IP address, so a DNS reverse lookup is used to get the host name.

        .DESCRIPTION
            This script gets the IP address of a vRealize Operations Manager server from a specified Vcenter server.
            Because the only way to get this information is to query the Extension Manager view, a full URL is returned.
            The script trims text from the URL to isolate the IP address, then uses a reverse lookup to get the DNS host name.
            If reverse lookup fails, the IP is returned.


        .PARAMETER VcenterServerObj
            An object representing a connected Vcenter server.

        .EXAMPLE
            Get-VropsServer -VcenterServerObj $connectedVC

        .OUTPUTS
            Returns string variable VropsHostName - either the IP address of the Vrops Manager server, or the hostname (if reverse lookup fails).

        .NOTES
            Author: Ian Summers

    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [psobject]
        $VcenterServerObj
    )

    try {

        Write-Verbose "Getting ExtensionManager view from Vcenter"
        $ExtensionMgrView = Get-View ExtensionManager -Server $VcenterServerObj -ErrorAction Stop

        Write-Verbose "Isolating the Vrops data from the Extension Manager view"
        $ExtensionServer = $ExtensionMgrView.ExtensionList | Where-Object {$_.Key -eq "com.vmware.Vrops"} | Select-Object -ExpandProperty Server

        Write-Verbose "Getting the server IP from the registered Vrops plugin's URL property"
        $VropsServerIP = $ExtensionServer.Url.Replace("https://", "").Replace("/vropsPlugin.zip", "")

        try {

            Write-Verbose "Peforming reverse lookup on $VropsServerIP to obtain hostname"
            $VropsHostName = Resolve-DnsName -Name $VropsServerIP -Type PTR | ForEach-Object {$_.NameHost} -ErrorAction Stop

        }
        catch {

            #catch exception and send error items to log
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName

            Write-Verbose "ERROR: DNS reverse lookup failed, returning IP address instead."
            Write-Verbose "     Exception: $ErrorMessage"
            Write-Verbose "   Failed Item: $FailedItem"

            Write-Verbose "Setting host name variable to be IP address since no reverse lookup data was found"
            $VropsHostName = $VropsServerIP

        }

    }

    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Get-VropsServer failed, exception below."
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"


    }

    Write-Verbose "Returning Vrops server name from function $($PSCmdlet.MyInvocation.MyCommand.Name)"
    return $VropsHostName

}
