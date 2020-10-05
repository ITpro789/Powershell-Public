<#	
	.NOTES
	===========================================================================
	 Created with: 	Microsoft PowerShell ISE
	 Created by:   	Sohail Pathan
	 Filename:      Take-Two Interactive answer
	===========================================================================
#>


#First thing’s first, import the csv as a variable.  Use this variable for all subsequent tasks.
$Users = import-csv -Path "C:\users\Public\users.csv"

#How many users are there?
$TotalUsers = $Users.Count
Write-host -f Green "Total Users: "-NoNewline; write-host -f Yellow "$TotalUsers"

#What is the total size of all mailboxes?
$Mailbox = $Users | select -ExpandProperty mailboxsizeGB
$TotalMailboxSize = $mailbox | Measure-Object -Sum | select -ExpandProperty sum
Write-host -f Green "Total size of Mailboxes: "-NoNewline; write-host -f Yellow $TotalMailboxSize

#How many accounts exist with non-identical EmailAddress/UserPrincipalName? Be mindful ofcase sensitivity.
$Emailaddress = $Users  | Select -ExpandProperty EmailAddress
$UPN = $Users | Select -ExpandProperty UserPrincipalName
$descripency = Compare-Object -CaseSensitive $Emailaddress $UPN | ?{$_.sideindicator -eq "=>"}
$totalDescripency = $descripency.Count
Write-host -f Green "Total non-identical Email/UPN (Case Sensitive): "-NoNewline; write-host -f Yellow $totalDescripency

#Same as question 3, but limited only to Site: NYC
$MailboxNYC = $Users |  ?{$_.Site -eq "NYC"} | select -ExpandProperty mailboxsizeGB
$TotalMailboxSizeNYC = $mailboxNYC | Measure-Object -Sum | select -ExpandProperty sum
Write-host -f Green "Total size of Mailboxes (NYC): "-NoNewline; write-host -f Yellow $TotalMailboxSizeNYC

#How many Employees (AccountType: Employee) have mailboxes larger than 10 GB? (remember MailboxSizeGB is already in GB.)
$Employees = $Users| ?{$_.AccountType -eq "Employee"} 
$Employees | ForEach-Object { $_.mailboxsizeGB = [math]::Round($_.MailboxSizeGB)}
$Employees = $Employees | ?{$_.mailboxsizeGB -ge "10"}
$TotalEmployee10GB = $Employees.Count
Write-host -f Green "Total Employees that have larger than 10GB Mailboxes: "-NoNewline; write-host -f Yellow $TotalEmployee10GB

#Provide a list of the top 10 users with EmailAddress @domain2.com in Site: NYC by mailbox size, descending.
$Top10users = $Users | ?{$_.emailaddress -like "*@domain2.com" -and $_.site -eq "NYC"} | Sort-Object mailboxsizegb -Descending
$Top10users

#The boss already knows that they’re @domain2.com; he wants to only know their usernames, that is, the part of the EmailAddress before the “@” symbol.should look like: “user1 user2 … user10”
$top10username = $Top10users | select -ExpandProperty emailaddress 
$top10username -replace "@domain2.com","" -join " "; [char]::ConvertFromUtf32(0x1f603)

#Create a new CSV file that summarizes Sites, using the following headers: Site, TotalUserCount, EmployeeCount, ContractorCount, TotalMailboxSizeGB, AverageMailboxSizeGB
#a. Create this CSV file based off of the original Users.csv.  Note that the boss is picky when
#it comes to formatting – make sure that AverageMailboxSizeGB is formatted to the
#nearest tenth of a GB (e.g. 50.124124 is formatted as 50.1).  You must use PowerShell to
#format this because Excel is down for maintenance.

#Gets a list of unique sites
$Sites = $Users | select -ExpandProperty site -Unique

#Clears Variable
$BossCSV = @()
$Data = @()

foreach($Site in $Sites)
{
    #Data based on the specific site
    $Data = $Users | ?{$_.site -eq $site}

    #Working off the $data variable, gets list of employees.
    $EmployeeCount = $data | ?{$_.accounttype -eq "Employee"}

    #List of contractors for that site
    $ContractorCount = $data | ?{$_.accounttype -eq "Contractor"}

    #Total mailbox site for that site (also rounding the number to 1st decemal place)
    $Mailboxsize = $data  | select -ExpandProperty mailboxsizeGB | Measure-Object -Sum | select -ExpandProperty sum
    $TotalMailboxsize = [math]::round($Mailboxsize,1)

    #Average mailbox site for that site (also rounding the number to 1st decemal place)
    $AvgMailboxsize = $data  | select -ExpandProperty mailboxsizeGB | Measure-Object -Average | select -ExpandProperty average
    $TotalAvgMailboxsize = [math]::round($AvgMailboxsize,1)

    #Creating a PSCustomObject here.
    $row = [PSCustomObject] @{
    Site = $site
    TotalUserCount = $data.Count
    EmployeeCount = $EmployeeCount.Count
    ContractorCount = $ContractorCount.Count
    TotalMailboxSizeGB = $TotalMailboxsize
    AverageMailboxSizeGB = $TotalAvgMailboxsize 
    }

    #at the end of each foreach object, it adds it into the main variable.
    $BossCSV += $row
}

#Exports main variable to CSV format
$BossCSV | export-csv C:\Users\Public\bossrequest.csv -NoTypeInformation

#Opens CSV with whatever working CSV opener you have on the computer.  (obviously not MS excel since it's down for maintanance...)
ii C:\Users\Public\bossrequest.csv 