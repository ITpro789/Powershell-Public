<#	
	.NOTES
	===========================================================================
	 Created with: 	Microsoft PowerShell ISE
	 Created on:   	04/02/2019 11:21
	 Created by:   	Sohail Pathan
	 Filename:      DirectAccess-Status.ps1
	===========================================================================
	.DESCRIPTION
		Script Checks:
        1. Direct Access Componant status
        2. Direct Access Connection status statistics
        3. Total Connected users for each server
        4. Pass/Fail status depending on health status of DA server.

        Note: 
        Please enter the name of each Direct Access server under the variable $server. 
#>


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
#                                   DirectAccess
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#region DirectAccess

#Please enter the Direct Access Server names below:
$Servers = @"
DAServer1
DAServer2
DAServer3
DAServer4
DAServer5
DAServer6
"@ -split "`r`n"

$Components = "Server,Services,Network Security,IPsec..."
$DirectAccessTable = @()


foreach ($Server in $Servers)
{

#Resets $Connected Variable to "0" at each loop.
$Connected = "0"

#Checks the health state of each Direct Access box
$DATest = Get-RemoteAccessHealth -ComputerName $server | ?{$_.healthstate -ne "Disabled"}

#Checks Total users connected to Direct Access Box
$totalDA = Get-RemoteAccessConnectionStatisticsSummary -ComputerName $server

#Breaks down the connected numbers into variable to use for the report
$Connected = $totalDA.TotalDAConnections

#IF command for HealthState Check and Connected Users
If(($DATest | ?{$_.HealthState -eq "OK"}) -and ($Connected -ne "0"))
 {
    $Result = "Pass"
    $HealthState = "OK"
 }
 Else
 {
    $Result = "Failed"
    $HealthState = "NA"
 }


    $Row = [PSCustomObject] @{
    Server = $Server
    Component = $Components
    HealthState = $HealthState
    ConnectedUsers = $Connected
    Result = $Result
    }
    $DirectAccessTable += $Row
}
$DirectAccessTable | ft -AutoSize

$Total = ($DirectAccessTable | Measure-Object -Property ConnectedUsers -Sum).Sum

Write-Host -f Green "Total users connected: $total"

#endregion DirectAccess