Function Connect-vROM () {

    <#
        .SYNOPSIS
            Connect to a target vRealize Operations Manager instance,

        .DESCRIPTION
            This script is an internal function to connect to a vROM.

        .PARAMETER Credential
            Credential to use for connection.

        .PARAMETER VromServer
            vROM server to connect to

        .PARAMETER VromAuthDomain
            vROps manager requires an authentication domain specified at connection time, this parameter is used to specify it.

        .EXAMPLE
            $ConnectedOM = Connect-vROM -VromServer che-n-vrom-01.sitcorp.local -Credential $OMCreds -VromAuthDomain Sitcorp

        .OUTPUTS
            VIServer Object containing connected vROM Server data.

        .NOTES
            Author: Ian Summers
    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [string]$VromServer,
        [Parameter(mandatory = $true)]
        [string]$VromAuthDomain,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential

    )

    try {

        Write-Verbose "Attempting to connect to vRealize Operations Manager server $VromServer"
        $ConnectedOM = Connect-OMServer -Server $VromServer -Credential $Credential -AuthSource $VromAuthDomain -ErrorAction Stop

    }

    catch {

        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Connection to vRealize Operations Manager server failed."
        Write-Verbose "  Connection parameters were:"
        Write-Verbose "                Server: $VromServer"
        Write-Verbose "                  User: $Credential.UserName"
        Write-Verbose "            Authdomain: $VromAuthDomain"
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"

        Write-Verbose "Setting connected server object to null value."
        $ConnectedOM = $null
    }

    Write-Verbose "Returning object to caller from function: $($PSCmdlet.MyInvocation.MyCommand.Name)."
    return $ConnectedOM

}