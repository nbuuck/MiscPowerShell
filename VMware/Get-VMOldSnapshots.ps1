$test = Get-Command Get-VM
if(!$test){
	Write-Error "Not in vSphere PowerCLI. Exiting."
	return
}
$ageThresholdDays = 7
$vms = Get-VM
foreach($vm in $vms) {
	foreach($snap in (Get-Snapshot -VM $vm)) {
		$now = Get-Date
		$diff = [Math]::Abs($now-$snap.Created)
		if($diff -gt $ageThresholdDays) { 
			Write-Host $vm.Name" - "$snap.Name" - "$snap.Created
		}
	}
}