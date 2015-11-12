$RemapPairs = @(
    (New-Object -TypeName PSObject -Property @{OldPath="\\ntserv5\EAS";NewPath="\\ntserv.doitbestcorp.com\Departments\Logistics\EAS"})
);

$DriveLetters = (Get-Item -Path "HKCU:Network").GetSubKeyNames();
$DriveLetters | ForEach-Object {
    $DriveLetter = $_;
    $DriveMapKey = (Get-Item -Path "HKCU:Network\$DriveLetter");
    $RemapPairs | ForEach-Object {
        $RemapPair = $_;
        $RemotePath = $DriveMapKey.GetValue("RemotePath").TrimEnd('\');
        if($RemotePath.ToLower() -eq $RemapPair.OldPath.ToLower()){
            NET USE $DriveLetter":" /DELETE;
            NET USE $DriveLetter":" $RemapPair.NewPath /PERSISTENT:YES;
        }
    }
}
