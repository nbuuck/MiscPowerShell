$shares = Get-WmiObject -Class Win32_Share
$countExists = 0;
$countTotal = 0;
foreach($share in $shares) {
	$countTotal++;
	$testPath = "$($share.Path)\DfsrPrivate";
	if(Test-Path $testPath){
		$countExists++;
		Write-Host $testPath;
	}
};
Write-Host "$countExists/$countTotal shares had a DFSR folder.";