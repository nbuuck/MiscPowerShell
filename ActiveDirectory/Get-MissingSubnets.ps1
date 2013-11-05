# nbuuck@apterainc.com
# Watches the netlogon log for hosts in subnets that aren't present in AD Sites & Services so we can add them.

$logName = "$($Env:SystemRoot)\debug\netlogon.log"
$dateToGet = (Get-Date).AddDays(-1).ToString("MM/dd")

$log = (Get-Content $logName) -match "NO_CLIENT_SITE"
$events = @()
foreach($line in $log){
	if($line -eq $null) { break }
	$line = $line.TrimStart("`0") # NETLOGON occassionally spams NULL character into file if you tried editing it.
	$parts = $line.Split(' ')
	
	# Compose an object so PowerShell can work with the data.
	$obj = New-Object PSObject -Property @{
		Date = $parts[0]
		Time = $parts[1]
		Hostname = $parts[4]
		InetAddress = $parts[5]
	}
	$events += $obj
}
if($events.Count -eq 0) { Write-Host "No events to send, exiting... "; return }
$events = $events | Select -Unique InetAddress, Hostname | Sort-Object InetAddress | FT -AutoSize | Out-String

$body = "The following hosts are contacting the domain in round robin mode because the host resides in a subnet that is not registered in AD Sites & Services:`n"
$body += $events

$smtpServer = "fe10mail-relay.franklin.fele"
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = "donotreply@fele.com"
$msg.ReplyTo = "donotreply@fele.com"
$msg.To.Add("servers@fele.com")
$msg.subject = "$($Env:COMPUTERNAME) - AD Sites & Services - Unregistered Subnets"
$msg.body = $body
$msg.IsBodyHtml = $false
$smtp.Send($msg)