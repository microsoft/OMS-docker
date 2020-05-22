
Start-Transcript -Path fileSystemWatcherTranscript.txt
Write-Host "Removing Existing Event Subscribers"
Get-EventSubscriber -Force | ForEach-Object { $_.SubscriptionId } | ForEach-Object { Unregister-Event -SubscriptionId $_ }
Write-Host "Starting File System Watcher for config map updates"
$FileSystemWatcher = New-Object System.IO.FileSystemWatcher
$Path = "C:\etc\config\settings"
$FileSystemWatcher.Path = $Path
$FileSystemWatcher.IncludeSubdirectories = $True
$EventName = 'Changed', 'Created', 'Deleted', 'Renamed'
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host $user
Write-Host $env:USERPROFILE

$Action = {
    $fileSystemWatcherStatusPath = "C:\etc\omsagentwindows\filesystemwatcher.txt"
    $fileSystemWatcherLog = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
    $Event.SourceEventArgs.ChangeType,
    $Event.TimeGenerated
    Write-Host $fileSystemWatcherLog
    Add-Content -Path $fileSystemWatcherStatusPath -Value $fileSystemWatcherLog
}

$ObjectEventParams = @{
    InputObject = $FileSystemWatcher
    Action      = $Action
}

ForEach ($Item in $EventName) {
    $ObjectEventParams.EventName = $Item
    $ObjectEventParams.SourceIdentifier = "File.$($Item)"
    Write-Host  "Starting watcher for Event: $($Item)"
    $Null = Register-ObjectEvent  @ObjectEventParams
}

Get-EventSubscriber -Force 

# keep this running for the container's lifetime, so that it can listen for changes to the config map mount path
try
{
    do
    {
        Wait-Event -Timeout 60
    } while ($true)
}
finally
{
    Get-EventSubscriber -Force | ForEach-Object { $_.SubscriptionId } | ForEach-Object { Unregister-Event -SubscriptionId $_ }
    Write-Host "Event Handler disabled."
}
