Function Disconnect-vCenter () {

    <#

        .SYNOPSIS
            Disconnects from a target vCenter Server

        .PARAMETER VcenterServerObj
            An object representing a connected vCenter server.

        .EXAMPLE
            $status = Disconnect-vCenter -VcenterServerObj $connectedVC

        .DESCRIPTION
            This script is an internal function to disconnect from a vCenter server that was connected to previously.

        .OUTPUTS
            DisconnectStatus, which is a null value if the connection is successfully disconnected.
            If the disconnect operation fails, the object returns a PSCustomObject:
                Status = error;
                Server = server name;
                ErrorMessage = $ErrorMessage;

        .NOTES
            Author: Ian Summers™

    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [psobject]$VcenterServerObj
    )

    try {

        Write-Verbose "Attempting to disconnect from vCenter server $vROMServer"
        $DisconnectStatus = Disconnect-VIServer -Server $VcenterServerObj -Confirm:$false -Verbose:$false -ErrorAction Stop

    }

    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Disconnection from vCenter server failed."
        Write-Verbose "            Server: $VcenterServerObj.Name"
        Write-Verbose "  Exception thrown: $ErrorMessage"
        Write-Verbose "       Failed item: $FailedItem"

        Write-Verbose "Setting return object properties with error data."
        $DisconnectStatus = [PSCustomObject]@{
            Status       = error;
            Server       = $VcenterServerObj.Name;
            ErrorMessage = $ErrorMessage;
        }
    }

    Write-Verbose "Returning object to caller from function: $($PSCmdlet.MyInvocation.MyCommand.Name). "
    return $DisconnectStatus

}