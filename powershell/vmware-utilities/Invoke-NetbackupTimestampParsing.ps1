function Invoke-NetbackupTimestampParsing () {

    <#
        .SYNOPSIS
            Parses a non-standard timestamp value from NetBackup application and converts to datetime object.

        .DESCRIPTION
            Uses regex to identify patterns in a non-standard timestamp and then reconstructs as a string.
            The string is then converted to a datetime object and returned.

        .PARAMETER InputString
            String value of the non-standard timestamp.

        .EXAMPLE
            $NetbackupTimestamp = "Sat Feb  2 18:09:45 2019 -0600,prdnbu20,t_tst_cvwtest_7d_etc"
            Invoke-NetbackupTimestampParsing -InputString $NetbackupTimestamp

        .NOTES
            Author:  Ian Summers

        .OUTPUTS
            Returns a PowerShell datetime object.

    #>
    [CmdletBinding()]
    param(
        [parameter(mandatory = $true)]
        [string]
        $InputString

    )

    try {

        Write-Verbose "Setting up date-parsing arrays."
        $DaysOfWeek = "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
        $MonthsOfYear = "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"

        Write-Verbose "Using a regex to find a time value."
        $ExtractedTime = [regex]::Match($InputString, '\d{1,2}:\d{2}:\d{2}').Value

        Write-Verbose "Using a regex to find a year value."
        $ExtractedYear = [regex]::Match($InputString, '(?<![+-:\w])\d{4}(?!:\w)').Value.Trim()

        Write-Verbose "Using a regex to find the day of the month."
        $ExtractedDayofMonth = [regex]::Match($InputString, '(?<![+-:\d\w])\d{1,2}(?!:\d\w)').Value.Trim()

        Write-Verbose "Using a regex to find the day of the week."
        $ExtractedDayOfWeek = [regex]::Match($InputString, '^\w{3}').Value

        Write-Verbose "Using a regex to find the month."
        $ExtractedMonth = [regex]::Match($InputString, '\s\w{3}\s').Value.Trim()

        Write-Verbose "Getting full values to construct a datetime-convertible string."
        $ConstructorDayOfWeek = $DaysOfWeek | Where-Object {$_ -like "$($ExtractedDayOfWeek)*"}
        $ConstructorMonth = $MonthsOfYear | Where-Object {$_ -like "$($ExtractedMonth)*"}

        Write-Verbose "Constructing a convertible datetime string"
        $ConstructedDateTime = $ConstructorDayOfWeek + ", " + $ConstructorMonth + " " + $ExtractedDayOfMonth + ", " + $ExtractedYear + " " + $ExtractedTime

        Write-Verbose "Converting constructed datetime string to a datetime object"
        $DateTimeConverter = [System.ComponentModel.DateTimeConverter]::new()
        $ReturnObject = $DateTimeConverter.ConvertFromString($ConstructedDateTime)

        Write-Verbose "Returning converted datetime object."
        return $ReturnObject

    }

    catch {

        ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        Write-Verbose "ERROR: Datetime conversion failed."
        Write-Verbose "       Exception thrown: $ErrorMessage"
        Write-Verbose "            Failed item: $FailedItem"

        return $null

    }

}#end function