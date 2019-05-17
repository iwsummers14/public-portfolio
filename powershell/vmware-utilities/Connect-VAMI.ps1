Function Connect-VAMI () {

    <#
        .SYNOPSIS
            Connect to a target vCenter VAMI, returns the connected server as an object.

        .DESCRIPTION
            This script is an internal function to connect to a vCenter VAMI instance.

        .PARAMETER Credential
            Credential to use for connection.

        .PARAMETER VcenterServer
            vCenter Address to connect to.

        .EXAMPLE
            Connect-VAMI -Credential $VMcred -VcenterServer vcenter.contoso.com

        .NOTES
            Improvements Author: Ian Summers

        .OUTPUTS
            VIServer Object containing connected vCenter Server data.
    #>


    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [string]$VcenterServer,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    try {

        Write-Verbose "Attempting to connect to vCenter server $VcenterServer"
        $ConnectedVAMI = Connect-CisServer -Server $VcenterServer -Credential $Credential -ErrorAction Stop

    }


    catch {


        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Connection to vCenter server VAMI interface failed."
        Write-Verbose "  Connection parameters were:"
        Write-Verbose "            Server: $VcenterServer"
        Write-Verbose "              User: $($Credential.UserName)"
        Write-Verbose "  Exception thrown: $ErrorMessage"
        Write-Verbose "       Failed item: $FailedItem"

        Write-Verbose "Setting connected server object to null value."
        $ConnectedVAMI = $null
    }

    Write-Verbose "Returning object to caller from function: $($PSCmdlet.MyInvocation.MyCommand.Name)."
    return $ConnectedVAMI
}
