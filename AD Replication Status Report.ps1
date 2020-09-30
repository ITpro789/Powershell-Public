<#	
        .NOTES
        ===========================================================================
        Created with: 	Microsoft PowerShell ISE
        Created on:   	28/02/2019 15:00
        Created by:   	Sohail Pathan
        Filename:      AD-Replication-Status.ps1
        ===========================================================================
        Purpose of this script:
        Microsoft's "Repadmin" command was created for Command Prompt and thus the data presented cannot be extracted into CSV, HTML or converted into any other type of data format.
        I have not found any script online that does performs a full AD replication in PowerShell, thus I created this script so that I can use this for daily AD replication checks.

        Script Checks:
        1. Last successful replication for each server
        2. Any replication failures during the test
        3. formats data in [PSCustomObject] format, so that it could be formated to CSV or HTML.
        4. Pass/Fail status depending on status of the replication.

        Note: 
        The script will search the AD Forest for all the domain controllers and add them into the variable automatically.
#>


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
#                          AD Replication
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#region AD Replication

#Clears Tables
$ADReplicationTable = @()
$row = @()

#List of Domain Controllers we need to check AD Replication
$Servers = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ } | select -ExpandProperty name
foreach ($Server in $Servers)
{
    #Adds each server data of ad replication to the Array $RepData
    $RepData = Get-ADReplicationPartnerMetadata -Target $Server | select server, partner, LastReplicationSuccess, LastReplicationResult, ConsecutiveReplicationFailures

    #Clears variable below (will be used in the next loop)
    $DestDC = @()

    #This foreach Adds a column "Result" to each row of server it replicates against and cleans ADSI info to readable Server name.
    foreach($row in $RepData)
    {
        Add-Member -Input $row -MemberType NoteProperty -Name Result -Value "(NULL)" -force
        $PartnerDC = $row.partner.Split(",")
        $PartnerDC = $PartnerDC[1].Replace("CN=","")
        $DestDC += $PartnerDC
    }

    #Runs foreach loop against the server. 
    $RepData | ForEach-Object{
    
    #Lastreplicationresult result is above 0, this means there was a error in replication and will result in fail, 0 will result in pass.
    if($_.LastReplicationResult -match 0)
    {
        $Result = "Pass"
        write-host "Pass"
    }
    else
    {
        $Result = "Fail"
        write-host "Failed"
    }
} # <-- End of foreach-object 
    
    #Total replication failures
    $TotalFails = $RepData | select -ExpandProperty consecutivereplicationfailures | Measure-Object -Sum | select -ExpandProperty sum

    #Gets the most recent successful date/time of the replication
    $date = $RepData.LastReplicationSuccess
    $LastDate = $date | select -Last 1
    
    $Row = [PSCustomObject] @{
    "Source DC" = "$Server"
    "Destination DC" = "$DestDC"
    "Last Success" = $LastDate
    Failure = $TotalFails
    Result = $Result
    }

    $ADReplicationTable += $row

}

$ADReplicationTable | ft

#endregion
