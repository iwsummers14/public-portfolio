Function Disconnect-VAMI () {

    <#

        .SYNOPSIS
            Disconnects from a target vCenter Server's VAMI API

        .PARAMETER VamiServerObj
            An object representing a connected vCenter server VAMI API.

        .EXAMPLE
            $status = Disconnect-VAMI -VamiServerObj $connectedVAMI

        .DESCRIPTION
            This script is an internal function to disconnect from a vCenter server VAMI API that was connected to previously.

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
        [psobject]$VamiServerObj
    )

    try {

        Write-Verbose "Attempting to disconnect from vCenter server VAMI API"
        $DisconnectStatus = Disconnect-CisServer -Server $VamiServerObj -Confirm:$false -Verbose:$false -ErrorAction Stop

    }

    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Disconnection from vCenter server failed."
        Write-Verbose "            Server: $VamiServerObj.Name"
        Write-Verbose "  Exception thrown: $ErrorMessage"
        Write-Verbose "       Failed item: $FailedItem"

        Write-Verbose "Setting return object properties with error data."
        $DisconnectStatus = [PSCustomObject]@{
            Status       = error;
            Server       = $VamiServerObj.Name;
            ErrorMessage = $ErrorMessage;
        }
        
    }

    Write-Verbose "Returning object to caller from function: $($PSCmdlet.MyInvocation.MyCommand.Name). "
    return $DisconnectStatus

}
