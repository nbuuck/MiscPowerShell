# Return all Sites in the current domain.

[CmdletBinding()]
Param(
	[String]$DN = ""
)

# Load ActiveDirectory PS module if not active.
if((Get-Module | Where { $_.Name -eq "ActiveDirectory"}).Count -eq 0){
	Import-Module ActiveDirectory
}

# Parse the computer's domain if -DN wasn't specified.
if($DN -eq ""){
	$domain = ($ENV:USERDNSDOMAIN).Split('.')
	if($domain -eq "") {
		Write-Error "The computer is not a member of a Domain and -DN wasn't provided."
		return
	}
	foreach($sub in $domain){
		Write-Verbose "Parsed: $sub"
		$DN = $DN + ",DC=$sub"
	}
}

#Compose the complete DN of the container.
$DN = $DN.Remove(0,1) # Remove the leading ","
$DN = "CN=Sites,CN=Configuration,$DN"
Write-Verbose "DN: $DN"

# Retrieve the Site objects.
Get-ADObject -SearchBase "$DN" -Filter {objectClass -eq "site"} | Sort-Object Name | Select Name