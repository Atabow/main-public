param(
    [Parameter(Mandatory=$true, HelpMessage='File name.')]
    [ValidateNotNull()]
    [string] $FileName
)

$LogFilePath = "C:\CustomScriptExtension.{0}.log" -f [guid]::NewGuid().ToString()

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

WriteLog "Successfully executed the script!"
