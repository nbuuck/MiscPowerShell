$RemapPairs = @(
    (New-Object -TypeName PSObject -Property @{OldPath="\\ServerA\MyShare";NewPath="\\ServerB\MyShare"})
);

$DriveLetters = (Get-Item -Path "HKCU:Network").GetSubKeyNames();
$DriveLetters | ForEach-Object {
    $DriveLetter = $_;
    $DriveMapKey = (Get-Item -Path "HKCU:Network\$_");
    $RemapPairs | ForEach-Object {
        if($DriveMapKey.GetValue("RemotePath") -eq $_.OldPath){
            Write-Host "$DriveLetter needs remapped from $($_.OldPath) to $($_.NewPath)";
            NET USE $DriveLetter":" /DELETE;
            NET USE $DriveLetter":" $_.NewPath /PERSISTENT:YES;
        }
    }
}
