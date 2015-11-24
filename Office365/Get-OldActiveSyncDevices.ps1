$oldDevices = @()
$devices = Get-MobileDevice -ResultSize Unlimited
foreach($device in $devices){
	$stats = (Get-MobileDeviceStatistics -Identity $device.Guid.ToString())
	if($stats -eq $null){
		Write-Warning "Get-MobileDeviceStatistics for $($device.DeviceId) ($($device.DisplayUserName)) returned null."
	}
	if($stats.LastSyncAttemptTime -lt (Get-Date).AddDays(-30)){
		Write-Host "$($device.Guid) $($device.FriendlyName) $($stats.LastSyncAttemptTime) $($device.UserDisplayName)"
		$oldDev = New-Object PSObject -Property @{
			Guid = $device.Guid
			DeviceId = $device.DeviceId
			FriendlyName = $device.FriendlyName
			LastSyncAttemptTime = $stats.LastSyncAttemptTime
			UserDisplayName = $device.UserDisplayName
		}
		$oldDevices += $oldDev
	}
}
$oldDevices | Format-Table -Auto