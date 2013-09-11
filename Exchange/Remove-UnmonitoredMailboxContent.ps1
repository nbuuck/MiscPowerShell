# To register as a Scheduled Task:
# Program: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# Options: -command ". 'C:\Program Files\Microsoft\Exchange Server\V14\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; &'C:\scripts\Remove-UnmonitoredMailboxContent.ps1'"
$identities = ("postmaster","donotreply")
foreach($ident in $identities) {
	Search-Mailbox -Identity $ident -DeleteContent -Force
}