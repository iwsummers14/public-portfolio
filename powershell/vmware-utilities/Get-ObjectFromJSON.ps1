Function Get-ObjectFromJSON() {

    <#
        .SYNOPSIS
            Get an object with data from a .json file specified by the caller.

        .DESCRIPTION
            The purpose of this function is to import a config.json file as an object and return it to the caller.

        .PARAMETER JsonInput
            Input JSON file used to create the object

        .EXAMPLE
            $configObj = Get-ObjectFromJSON -JsonInput .\Data\config.json

        .OUTPUTS
            returnObj - PSObject - properties and content varies based on the JSON input structure.

        .NOTES
            Author: Ian Summers™

    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $JsonInput
    )

    try {

        Write-Verbose "Converting input file $JsonInput from JSON to a PowerShell Object"
        $ReturnObj = Get-Content -Path $JsonInput | ConvertFrom-Json -ErrorAction Stop

    }

    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Importing JSON file $jsonInput as an object failed."
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"
    }

    Write-Verbose "Returning object to caller from function: $($PSCmdlet.MyInvocation.MyCommand.Name)"
    return $ReturnObj


}#end of function