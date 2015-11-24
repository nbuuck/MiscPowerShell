<#
.SYNOPSIS
This script searches the local CA's certificate database for certificates that
expire within a statically-defined threshold and sends a list of any matching
certificates to one or more email recipients.
.NOTES
The method for retrieving the certificate data from the View COM object was
almost entirely derived from Francois-Xavier Cat's work at
http://www.lazywinadmin.com/2011/01/se-powershell-to-enumerate-info-from.html
#>

Clear-Host
$ThresholdDays = 30

# Instantiate and open a COM object that provides a view of the certificates.
# CACommonName will be on the CA cert, perhaps similar to "corporate-CA".
$CAName = "ServerName\CACommonName" # @TODO Configure this.
$CAView = New-Object -ComObject CertificateAuthority.View.1
$CAView.OpenConnection($CAName)
$CAView.SetResultColumnCount(4)

# Determine the indices of the columns we will retrieve.
# This is unavoidable because we must set which columns we want from the
#	view and we must know the index of the column in order to do so.
$IdxSerialNumber = $CAView.GetColumnIndex(0,"SerialNumber")
$IdxCommonName = $CAView.GetColumnIndex(0,"CommonName")
$IdxRequesterName = $CAView.GetColumnIndex(0,"Request.RequesterName")
$IdxNotAfter = $CAView.GetColumnIndex(0,"NotAfter") # Expiration date.

# Set the identified columns as result columns on the view instance.
$CAView.SetResultColumn($IdxSerialNumber)
$CAView.SetResultColumn($IdxCommonName)
$CAView.SetResultColumn($IdxRequesterName)
$CAView.SetResultColumn($IdxNotAfter)

# Opening the view returns an IEnumerable object.
$RowEnum = $CAView.OpenView()
$certs = @() # Collection of resulting rows as PSObjects for filtering later.
while($RowEnum.Next() -ne -1){

	# Like rows, we have to iterate over resulting columns as IEnumerables.
	# Store column values in an array for creation of a PSObject.
	$ColEnum = $RowEnum.EnumCertViewColumn()
	$ColValues = @()
	while($ColEnum.Next() -ne -1){
		$ColValues += $ColEnum.GetValue(0)
	}

	# Create a PSObject for easier use later.
	$CertObject = New-Object PSObject -Property @{
		SerialNumber = $ColValues[0]
		CommonName = $ColValues[1]
		RequesterName = $ColValues[2]
		NotAfter = [System.DateTime]$ColValues[3]
	}
	
	# Append the PSObject to our array of objects.
	$certs += $CertObject
	
}

# Iterate through the PSObject certs and find those that expire within
#	$ThresholdDays.
$now = (Get-Date)
$expiringCerts = @()
foreach($cert in $certs){

	$diffSpan = $cert.NotAfter.Subtract($now) # Returns System.TimeSpan
	
	# Must check for > 0 as negative values can easily be returned.
	if($diffSpan.Days -gt 0 -and $diffSpan.Days -lt $ThresholdDays){
		$expiringCerts += $cert
	}
	
}

# If any soon-to-be-expired certs were found, send a notification.
if($expiringCerts.Length -gt 0){

	# We format the output as a list because Outlook does bad things to our
	#	line breaks.
	$list = ($expiringCerts | Format-List | Out-String)
	$body = "The following certificates on $($CAName) are expiring " + `
		"in the next $ThresholdDays days:`n$list"
	$body = $body.Trim() # Get rid of trailing line breaks.

	$smtpServer = "smtp.domain.com" # @TODO Configure this.
	$msg = New-Object Net.Mail.MailMessage
	$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
	$msg.From = "donotreply@domain.com" # @TODO Configure this.
	$msg.ReplyTo = "donotreply@domain.com" # @TODO Configure this.
	$msg.To.Add("me@domain.com") # @TODO Configure this.
	$msg.subject = "$($Env:COMPUTERNAME) - Certificates Expiring"
	$msg.body = $body
	$msg.IsBodyHtml = $false
	$smtp.Send($msg)

}
