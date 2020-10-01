<#	
	.NOTES
	===========================================================================
	 Created with: 	Microsoft PowerShell ISE
	 Created on:   	04/02/2019 11:21
	 Created by:   	Sohail Pathan
	 Filename:      ADFS Check User.ps1
	===========================================================================
	.DESCRIPTION
		Script Checks:
        1. Finds ADFS Servers puts then into a variable.
        2. Finds event ID 4624 in the last 60 minutes to see if an account successfully logged on via ADSF.
#>

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
#                       Active Directory Federation Services (ADFS)
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#region ADFS
$ADFS = get-adcomputer -Filter {description -like "*ADFS*" -or DisplayName -like "*ADFS*"} | select -ExpandProperty name

$ADFSTable = @()
foreach ($Server in $ADFS)
{
$Check = Get-WinEvent -ComputerName $Server -FilterHashtable @{LogName='Security'; StartTime=(get-date).AddHours(-1); ID=4624} -MaxEvents 1

If($Check | ?{$_.Id -eq "4624"})
 {
    $Result = "Pass"
    $Message = "An account was successfully logged on."
 }
 Else
 {
    $Result = "Failed"
    $Message = "Please Check ADFS Server"
 }

    $Row = [PSCustomObject] @{
    Server = $Server
    TimeCreated = $Check.TimeCreated
    EventID = $Check.ID
    Message = $Message
    Result = $Result
    }

    $ADFSTable += $Row

}

$ADFSTable | Ft