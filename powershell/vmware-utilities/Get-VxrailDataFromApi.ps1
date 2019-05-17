function Get-VxrailDataFromApi () {

    <#
        .SYNOPSIS
            Connects to the REST API of a specified VxRail manager appliance to get requested data.

        .DESCRIPTION
            Connects to the REST API of a specified VxRail manager appliance to get requested data.
            Only does GET method, to stay consistent with the Get verb.
            Constructs a basic authentication request in conjunction with this operation.

        .PARAMETER Credential
            PSObject - PowerShell Credential object for the API user.
            API uses vSphere SSO domain for authentication.

        .PARAMETER VxrailManager
            String - FQDN of the VxRail manager appliance

        .PARAMETER ApiNamespace
            String - API Namespace in the format '/rest/vxm/v1/example' starting with the '/' character.

        .EXAMPLE
            $data = Get-VxrailDataFromApi -VxrailManager che-n-devvx-01.sitcorp.local -ApiNamespace /rest/vxm/v1/system

        .OUTPUTS
            Returns an object with the API response data converted from JSON to a PowerShell object.

        .NOTES
            Author: Ian Summers

    #>

    [CmdletBinding()]
    param(
        [Parameter(mandatory = $true)]
        [psobject]
        $Credential,
        [Parameter(mandatory = $true)]
        [string]
        $VxrailManager,
        [Parameter(mandatory = $true)]
        [string]
        $ApiNamespace

    )

    try {

        Write-Verbose "Converting password to plain text"
        $EncryptedPW = $Credential.Password
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($EncryptedPW)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        Write-Verbose "Constructing username/password pair"
        $User = $Credential.Username.ToString()
        $Pass = $UnsecurePassword
        $Pair = "${User}:${Pass}"

        Write-Verbose "Encoding pair as base64"
        $Bytes = [System.Text.Encoding]::ASCII.GetBytes($Pair)
        $Base64 = [System.Convert]::ToBase64String($Bytes)

        Write-Verbose "Constructing Authorization value"
        $BasicAuthorization = "Basic $Base64"

        Write-Verbose "Creating Web Request Header"
        $Header = @{ Authorization = $BasicAuthorization }

        $APIRequestParams = @{

            Uri = "https://" + $VxrailManager + $ApiNamespace
            Header = $Header
            SessionVariable = 'VxrSession'
            Method = 'Get'

        }

        Write-Verbose "Invoking Web Request"
        $APIResponse = Invoke-WebRequest @APIRequestParams -UseBasicParsing -ErrorAction Stop

        Write-Verbose "Converting response to an object for return"
        $ResponseObject = $APIResponse | ConvertFrom-Json -ErrorAction Stop

        Write-Verbose "Returning object with API response data"
        return $ResponseObject
    }

    catch {

        #catch exception and send error items to log
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Getting VXRail API data failed, exception below."
        Write-Verbose "      Exception thrown: $ErrorMessage"
        Write-Verbose "           Failed item: $FailedItem"

        return $null

    }

}
