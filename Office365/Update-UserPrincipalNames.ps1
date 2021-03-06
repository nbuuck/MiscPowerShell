<#
.SYNOPSIS
Update the userPrincipalName of all mail-enabled users for compatibility with Office 365.
In order to be compatible, the UPN of the user must match his/her email address in O365.
#>

Param ( [Switch]$Commit, [Switch]$Restore )

$backupFile = "UserPrincipalNames.bak"
$logFile = "Update-UserPrincipalNames.log"
$upnSuffix = "@domain.com" # This should be your organizations mail domain.

Clear-Host

if(!$Commit) {
	Write-Host -ForegroundColor Green "`nSIMULATION"
    Write-Host "Changes will NOT be committed to LDAP...`n"
} else {
    $answer = ""
    while($answer.ToLower() -ne "n" -and $answer.ToLower() -ne "y") {
		Write-Host -ForegroundColor Yellow "`nWARNING"
        $answer = Read-Host "Changes will be committed to LDAP. Continue? [y\n]"
    }
    if($answer.ToLower() -eq "n") {
        Write-Host "`nCancelled. Exiting...`n"
        return
    }	
}

Function Get-LogTimestamp {
	return (Get-Date).ToString("[yyyy-MM-dd HH:mm:ss] ")
}

Function Update-UPNs {

	Write-Host -ForegroundColor Yellow "`nUPDATE"
    Write-Host "Updating UPNs for users with an existing `"mail`" attribute.`n"

	$users = Get-ADUser -Properties userPrincipalName,samAccountName,mail,displayName `
		-LDAPFilter "(&(mail=*)(!(mail=*System*))(!(sAMAccountName=*SM_*)))" `
		| Sort-Object samAccountName
	#Remove-Item $logFile -errorAction silentlyContinue

	foreach($user in $users) {
		$newupn = $user.mail
		$posAt = $newupn.IndexOf('@')
		
		if($posAt -le 0){ continue }
		$newupn = $newupn.Substring(0, $posAt) + $upnSuffix
		$newupn = $newupn.ToLower()
		
		if(!$user.UserPrincipalName -or `
			$user.UserPrincipalName.ToLower() -ne $newupn)
		{
			$line = (Get-LogTimestamp) + 'UPDATE UPN for "' + $user.samAccountName + '" (' + $user.DisplayName + ") from "
			if(!$user.UserPrincipalName) {
				$line += "NULL"
			} else {
				$line += '"' + $user.UserPrincipalName + '"'
			}
			$line += " to `"$newupn`"."
			Out-File -Append -FilePath ".\$logFile" -InputObject $line.Trim()
			
			if($Commit) {
				Set-ADUser -Identity $user.samAccountName -UserPrincipalName $newupn
			}
		}
	}
}

Function Backup-UPNs {
	Write-Host -ForegroundColor Green "`nBACKUP"
    Write-Host "Writing backup of all ADUser UPNs to $backupFile.`n"
	Remove-Item $backupFile -errorAction silentlyContinue
	Get-ADUser -Properties userPrincipalName,samAccountName,mail `
		-LDAPFilter "(&(mail=*)(!(mail=*System*))(!(sAMAccountName=*SM_*)))" `
		| Sort-Object samAccountName `
		| ForEach-Object { $line=$_.samAccountName+","+$_.UserPrincipalName; Out-File -Append -FilePath ".\$backupFile" -InputObject $line }
}

Function Restore-UPNs {
	$file = Get-ChildItem | Where { $_.Name -eq $backupFile }
	if(!$file) {
		Write-Error "No file `"$backupFile`" in current directory."
		return
	}
	
	Write-Host -ForegroundColor Yellow "`nRESTORE"
    Write-Host "Restoring previous UPNs from `"$backupFile`"...`n"
	
	$content = Get-Content $file
	foreach($line in $content) {
		if(!$line.Contains(',')) { continue }
		$parts = $line.Split(',')
		if(!$parts.Length -eq 2) { continue }
		$log = (Get-LogTimestamp) + 'RESTORE UPN for "' + $parts[0] + '" to "' + $parts[1] + '".'
		Out-File -Append -FilePath ".\$logFile" -InputObject $log.Trim()
		
		if($Commit -and $parts[1] -ne "") {
			Set-ADUser -Identity $parts[0] -UserPrincipalName $parts[1]
		}
	}
}

if($Restore) {
	Restore-UPNs
} else {
	Backup-UPNs
	Update-UPNs
}