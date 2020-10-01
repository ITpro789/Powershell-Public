<#	
	.NOTES
	===========================================================================
	 Created with: 	Microsoft PowerShell ISE
	 Created on:   	06/04/2020 09:21
	 Created by:   	Sohail Pathan
	 Filename:      Delete Windows 7 Computers.ps1
	===========================================================================

    .DESCRIPTION
      On rare occasions the desktop support members can accidently restore the Windows 7 machine from the recycle bin, this can be a security risk.
      It is important to clear up recycle bin containing Windows 7 computers.
      
      1. The script will find all computers stored in the recycle bin with the Operating System of "Windows 7"
      2. It will confirm the location is in Recycle bin.
      3. If it conforms to second verification check, it will delete the computer.
#>

#Find Windows 7 Computers in AD
$Windows7 = get-adobject -filter 'objectclass -eq "computer" -and IsDeleted -eq $True -and operatingsystem -eq "Windows 7 Enterprise"' -IncludeDeletedObjects -Properties *

#Gives total count of Windows 7 computers in AD
write-host -f Green "Windows 7"
$Windows7.count

#Runs foreach loop and does a second level check to confirm if the machine is already in recycle bin and that it is indeed Windows 7 OS.
foreach ($computer in $Windows7)
{
    if(($computer | select -ExpandProperty isdeleted) -eq "true" `
    -and ($computer | select -ExpandProperty operatingSystem) -eq "Windows 7 Enterprise")
    {
        write-host -f Green "Computer has the attribute:     IsDelete"
        write-host -f Green "Computer Operating System:      Windows 7 Enterprise"
        Remove-ADObject $computer -Verbose
    }
    else
    {
        Write-host -f red "Does not conform to second verification check"
    }
}