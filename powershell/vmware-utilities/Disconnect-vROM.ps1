Function Disconnect-vROM() {

    <#
        .SYNOPSIS
            Disconnects from a target vROps Manager.

        .PARAMETER VromServerObj
            An object representing a connected vROps Manager server.

        .EXAMPLE
            $status = Disconnect-vROM -VromServerObj $connectedOM

        .DESCRIPTION
            This script is an internal function to disconnect from a vROps Manager server that was connected to previously.

        .OUTPUTS
            DisconnectStatus, which is a null value if the connection is successfully disconnected.
            If the disconnect operation fails, the object returns a PSCustomObject:
                Status = error;
                Server = server name;
                ErrorMessage = $ErrorMessage;

        .NOTES
            Author: Ian Summers

    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [psobject]$VromServerObj
    )

    try {

        Write-Verbose "Attempting to disconnect from vRealize Operations Manager server $($VromServerObj.Name)"
        $DisconnectStatus = Disconnect-OMServer -Server $VromServerObj -Confirm:$false -Verbose:$false -ErrorAction Stop

    }
    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Disconnection from vRealize Operations Manager server failed."
        Write-Verbose "            Server: $VromServerObj.Name"
        Write-Verbose "  Exception thrown: $ErrorMessage"
        Write-Verbose "       Failed item: $FailedItem"

        Write-Verbose "Setting return object parameters with error data."
        $DisconnectStatus = [PSCustomObject]@{
            Status       = error;
            Server       = $VromServerObj.Name;
            ErrorMessage = $ErrorMessage;
        }
    }

    Write-Verbose "Returning object to caller from function: $($PSCmdlet.MyInvocation.MyCommand.Name). "
    return $DisconnectStatus
}