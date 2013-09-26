cls

if($args.Length -lt 1) {
	Write-Host "WOLPacket.ps1 [macaddress]"
	return
}

$addr = $args[0];
$addrClean = $addr -replace "[^a-fA-F0-9]", ""

if(-not $addrClean.Length -eq 12) {
	Write-Host "Invalid MAC address."
	return
}else{
	Write-Host "Waking up" $addr "($addrClean)."
}

$payload = "FFFFFFFFFFFF"
for($i = 0; $i -lt 16; $i++) {
	$payload = "$payload$addrClean"
}

$payloadBytes = @()
$i = 0
while($i -lt ($payload.Length - 1)) {
	$strByte = $payload.substring($i, 2)
	$asByte = [Convert]::ToByte($strByte, 16)
	$payloadBytes += $asByte
	$i = $i + 2
}

# UDP datagram handling from 
# http://pshscripts.blogspot.com/2008/12/send-udpdatagramps1.html

[int] $port = 9
$IP = "255.255.255.255"
$address = [system.net.IPAddress]::Parse($IP) 
 
# Create IP Endpoint 
$end = New-Object System.Net.IPEndPoint $address, $port 
 
# Create Socket 
$saddrf   = [System.Net.Sockets.AddressFamily]::InterNetwork 
$stype    = [System.Net.Sockets.SocketType]::Dgram 
$ptype    = [System.Net.Sockets.ProtocolType]::UDP 
$sock     = New-Object System.Net.Sockets.Socket $saddrf, $stype, $ptype 
$sock.TTL = 5
 
# Connect to socket 
$sock.Connect($end)
 
# Send the buffer 
$sent = $sock.Send($payloadBytes) 
"{0} characters sent to: {1} " -f $sent,$IP 
