param(
    [Parameter(Mandatory=$true, HelpMessage='Application disk size.')]
    [int] $appDiskSizeInGB,

    [Parameter(Mandatory=$true, HelpMessage='Log disk size.')]
    [int] $logDiskSizeInGB
)

$LogFilePath = "C:\CustomScriptExecution.{0}.log" -f [guid]::NewGuid().ToString()

function WriteLog([string] $message)
{
    $date = Get-Date
    $datedMessage = "$date : $message"
    Add-Content -Path $LogFilePath -Value $datedMessage -Force
}

function WriteErrorAndExit([string] $errorMessage)
{
    WriteLog $errorMessage
    Start-Sleep -Seconds 5
    [Environment]::Exit(1)
}

function CreateDrive()
{
    param
    (
        [Parameter(Mandatory=$true)]
        [int] $diskNumber,
        [Parameter(Mandatory=$true)]
        [char] $driveLetter,
        [Parameter(Mandatory=$true)]
        [int] $ntfsAllocationUnitSize
    )

    try
    {
        $vol = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if (!$vol)
        {
            WriteLog "Initializing disk '$diskNumber'"
            Initialize-Disk -Number $diskNumber

            WriteLog "Creating partition and assigning drive letter '$driveLetter'"
            New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter $driveLetter
           
            $confirmpreference = 'none' 
            WriteLog "Formating drive '$driveLetter' with confirm preference = $confirmpreference"
            Format-Volume -DriveLetter $driveLetter -Confirm:$false -AllocationUnitSize $ntfsAllocationUnitSize -ErrorAction Stop
            WriteLog "Drive '$driveLetter' is ready to use."
        }
        else
        {
            WriteLog "Drive '$driveLetter' already exists!"
        }
    }
    catch
    {
        WriteErrorAndExit "Error creating log drive: $($_.Exception.Message)."
    }
}

function CreateManagedDiskDrive()
{
    param
    (
        [Parameter(Mandatory=$true)]
        [char] $driveLetter,
        [Parameter(Mandatory=$true)]
        [string] $type,
        [Parameter(Mandatory=$true)]
        [long] $diskSizeGB,
        [Parameter(Mandatory=$true)]
        [int] $ntfsAllocationUnitSize
    )

    try
    {
        $vol = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if (!$vol)
        {
            [long]$diskSizeInBytes = $diskSizeGB * 1024 * 1024 * 1024
            $disk = Get-Disk | Where-Object NumberOfPartitions -eq 0 |  Where-Object PartitionStyle -eq 'RAW' | Where-Object Size -eq $diskSizeInBytes

            if(!$disk) {
                WriteLog "No disk to create $type drive"
                return $false
            }

            CreateDrive -diskNumber $disk[0].Number -driveLetter $driveLetter -ntfsAllocationUnitSize $ntfsAllocationUnitSize
        }
        else
        {
            WriteLog "$type drive $driveLetter already exists!"
	    }

        return $true
    }
    catch
    {
        WriteErrorAndExit "Error creating $type drive: $($_.Exception.Message)."
    }

    return $false
}

$blockSize4KB = 4096

WriteLog "Creating application drive"
$logDriveRet = CreateManagedDiskDrive -driveLetter "X" -type "Data" -diskSizeGB $appDiskSizeInGB -ntfsAllocationUnitSize $blockSize4KB

WriteLog "Creating log drive"
$logDriveRet = CreateManagedDiskDrive -driveLetter "Z" -type "Log" -diskSizeGB $logDiskSizeInGB -ntfsAllocationUnitSize $blockSize4KB

WriteLog "Successfully executed the script!"
