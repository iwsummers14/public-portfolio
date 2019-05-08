Function New-MockingSpongebobString () {


    <#
    .SYNOPSIS

        Generates a Mocking Spongebob string so you don't have to.

    .DESCRIPTION

        The purpose of this script is to convert a string from its existing case to MoCkInG sPoNgEbOb case.

    .PARAMETER InputString

        string - the string you wish to convert

    .OUTPUTS

        outputs a string in MoCkInG sPoNgEbOb case.

    .NOTES

        Author: Ian Summers


#>

    [CmdletBinding()]
    Param (
        [Parameter(mandatory = $true)]
        [string]
        $InputString
    )

    [string]$OutputString = $null

    $Length = $InputString.Length

    for ($i = 0; $i -lt $Length; $i++) {

        #put the first character in no matter what
        if ($i -eq 0){
            $OutputString = $OutputString + $InputString[$i]
            continue
        }
        else {

            #look to see if current char was a space
            if ([char]::IsWhitespace($InputString[$i]) -or [char]::IsPunctuation($InputString[$i])) {

                $OutputString = $OutputString + $InputString[$i]
                continue
            }

            #look to see if previous char was a space or punctuation
            elseif ([char]::IsWhitespace($OutputString[$($i - 1)]) -or [char]::IsPunctuation($InputString[$($i - 1)]) ) {

                #skip the space when evaluating previous char
                if ([char]::IsLower($OutputString[$($i-2)])){
                    $OutputString = $OutputString + $InputString[$i].ToString().ToUpper()
                }
                else{
                    $OutputString = $OutputString + $InputString[$i].ToString().ToLower()
                }

            }

            #change current case based on previous character
            else {
                if ([char]::IsLower($OutputString[$($i - 1)])) {
                    $OutputString = $OutputString + $InputString[$i].ToString().ToUpper()
                }
                else {
                    $OutputString = $OutputString + $InputString[$i].ToString().ToLower()
                }
            }

        }

    }#end for loop

    return $OutputString

}#end function
