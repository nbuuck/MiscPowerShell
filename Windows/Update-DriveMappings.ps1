$RemapPairs = @(
    (New-Object -TypeName PSObject -Property @{OldPath="\\ServerA\MyShare";NewPath="\\ServerB\MyShare"})
);

$DriveLetters = (Get-Item -Path "HKCU:Network").GetSubKeyNames();
$DriveLetters | ForEach-Object {
    $DriveLetter = $_;
    $DriveMapKey = (Get-Item -Path "HKCU:Network\$DriveLetter");
    $RemapPairs | ForEach-Object {
        $RemapPair = $_
        if($DriveMapKey.GetValue("RemotePath") -eq $RemapPair.OldPath){
            NET USE $DriveLetter":" /DELETE;
            NET USE $DriveLetter":" $RemapPair.NewPath /PERSISTENT:YES;
        }
    }
}
