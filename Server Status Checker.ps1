<#	
	.NOTES
	===========================================================================
	 Created with: 	Microsoft PowerShell ISE
	 Created on:   	13/07/2019 09:21
	 Created by:   	Sohail Pathan
	 Filename:      Server Status Checker.ps1
	===========================================================================

    .DESCRIPTION
      The script will provide the data on RAM, CPU and will provide a final result of server,
      This will either be a Pass, Warning or Fail.

      Pass    = Under 95% CPU or Ram Utilisation and Server being online
      Warning = Above 95% CPU or Ram Utilisation and Server being online
      Fail    = Unable to connect to the server.

    .PARAMETER Computername
       Enter the computer name which you'd like to check the Online, CPU, Ram Status. 
  
    .EXAMPLE
      Get-ComputerStatus -Computername Server1
#>

Function Get-ComputerStatus 
{
  Param
  (
    [parameter(Mandatory=$true)]
    [String]$computername
  ) 
  Begin
  {
    $CpuRamTable = @()
  }

  Process
  {
    #Writes-host and then clears Variables
    Write-Host "Processing $computername"
    $Check = $null
    $Processor = $null
    $ComputerMemory = $null
    $RoundMemory = $null
    $Object = $null
 
        # It will now attempt to connect to each server with Try Command
        Try
        {
            # Processor utilization
            $Processor = (Get-WmiObject -ComputerName $computername -Class win32_processor -ErrorAction Stop | Measure-Object -Property LoadPercentage -Average | Select-Object Average).Average
            $RoundProcessor = [math]::Round($Processor, 0)
            $RoundProcessor2 = [String]$RoundProcessor + "%"

            # Memory utilization
            $ComputerMemory = Get-WmiObject -ComputerName $computername -Class win32_operatingsystem -ErrorAction Stop
            $Memory = ((($ComputerMemory.TotalVisibleMemorySize - $ComputerMemory.FreePhysicalMemory)*100)/ $ComputerMemory.TotalVisibleMemorySize)
            $RoundMemory = [math]::Round($Memory, 0)
            $RoundMemory2 = [String]$RoundMemory + "%"

            # Description of Server
            $Description = Get-ADComputer -Identity $computername -Properties * | select -ExpandProperty description

            # HDD Utilisation (% Space Used UP)
            $disks = Get-WmiObject Win32_LogicalDisk -ComputerName $computername -Filter "DriveType='3'" -ErrorAction SilentlyContinue |
            Select-Object DeviceID, @{N="Used";e={[math]::Round($($_.Size - $_.FreeSpace) / $_.Size * 100)}}
            $Disk0 = $disks[0].used
            $Disk1 = [string]$disks[0].used + "%"

            #This checks if the server is ONLINE or OFFLINE.
            $Check = Test-Path -Path "\\$computername\c$" -ErrorAction SilentlyContinue
            If($Check -match "True") {$Status = "True"} else {$Status = "False"}


            # If the CPU, RAM or HDD is above 95%, it will flag $Result as WARNING, or it will pass.
            If($Processor -ge 95 -or $RoundMemory -ge 95 -or $disk0 -ge 95)
            {
                $Result = "Warning"
            }
            Else
            {
                $Result = "Pass"
            }
        
            #This IF command is important as it overwrites "WARNING" status to "FAIL" if the server ONLINE status is false.
            If($Check -match "False") {$Result = "Fail"}
 
        }
            Catch # If the Try fails, catch will add the following data into the designated variables. 
        {
            Write-Warning "Unable to connect to server" 
            $Server = $computername
            $Description = "Connection to $computername failed"
            $Status = "False"
            $RoundProcessor2 = "---"
            $RoundMemory2 = "---"
            $disk1 = "---"
            $Result = "Fail"
             
        }#End of Try Command.

                #Table which will be added to the main table.
                $Row = [PSCustomObject] @{
                Server = $computername
                Description = $Description
                Online = $Status
                CPU = $RoundProcessor2
                RAM = $RoundMemory2                
                "C:\" = $disk1
                Result = $Result
                }
                $Row
  }
}
#>

<#

---------------------------------------------------------------------------
-  Use this section to check multiple computer and put them into a table. -
---------------------------------------------------------------------------


$CpuRamTable =@()

#Please enter the list of servers you would like

$computers = @"
Server1
Server2
Server3
"@ -split "`r`n"

ForEach($computer in $computers)
{
    $data = get-computerStatus -computername $computer
    $CpuRamTable += $data
}

$CpuRamTable | Sort-Object Description | ft

#>