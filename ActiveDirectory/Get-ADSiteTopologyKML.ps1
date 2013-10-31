Clear-Host
Import-Module ActiveDirectory

# CONSTANTS
$kmlFile = "AD-SitesTopology.kml"

# FUNCTIONS
Function Get-SiteCoordinates($siteList){
	$locations = ""
	$first = $true
	foreach($siteDN in $siteList){
		$site = Get-ADObject `
			-SearchBase $sitesSearchBase `
			-Filter { objectClass -eq "site" -and distinguishedName -eq $siteDN } `
			-Properties Location
		if($site -ne $null){
			if(-not $first) { $locations += "`t`t`t`t`t" } else { $first = $false }
			$locations += "$($site.Location)`n"
		}
	}
	$locations = $locations.TrimEnd("`n")
	return $locations
}

# Get the domain name for use in search bases for AD queries.
$domains = $Env:USERDNSDOMAIN
if($domains -eq $null) { return }
$domains = $domains.Split(".")
foreach($domain in $domains){
	$dnSuffix += "DC=$domain,"
}
$dnSuffix = $dnSuffix.TrimEnd(',')

# Build search bases for Containers with Site information.
$sitesSearchBase = "CN=Sites,CN=Configuration,$dnSuffix"
$siteLinksBase = "CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,$dnSuffix"

# Get all Inter-Site Transport links.
$siteLinks = Get-ADObject `
	-Filter { Name -ne "IP" } `
	-SearchBase $siteLinksBase `
	-Properties SiteList,Cost,ReplInterval | `
	Sort-Object Name

# Get all Site objects.
$sites = Get-ADObject `
	-Filter { objectClass -eq "site" } `
	-SearchBase $sitesSearchBase `
	-Properties Location | `
	Sort-Object Name

# Read our template (minimize KML building in code).
$kml = Get-Content .\Template-ADSiteTopologyKML.xml
$places = ""

# Represent each Site as a single-point Placemark.
foreach($site in $sites){

	$serversBase = "CN=Servers,$($site.DistinguishedName)"
	$servers = Get-ADObject `
		-SearchBase $serversBase `
		-Filter { objectClass -eq "server" }
	
	$places += "`t`t<Placemark>`n"
	if($servers -ne $null){
		$places += "`t`t`t<styleUrl>#site-with-dc</styleUrl>`n"
	}else{
		$places += "`t`t`t<styleUrl>#site-without-dc</styleUrl>`n"
	}
	$places += "`t`t`t<name>$($site.Name)</name>`n"
	$places += "`t`t`t<description></description>`n"
	$places += "`t`t`t<Point>`n"
	$places += "`t`t`t`t<coordinates>$($site.Location),0.0</coordinates>`n"
	$places += "`t`t`t</Point>`n"
	$places += "`t`t</Placemark>`n"
}

# Represent each Site Link as a two point LineString.
# Not sure how this will behave in domains containing Site Links
#		with more than two sites. We follow MS' recommendation and express
#		our topology use Links with two Sites in each Link.
foreach($siteLink in $siteLinks){
	$places += "`t`t<Placemark>`n"
	$places += "`t`t<styleUrl>#site-link</styleUrl>`n"
	$places += "`t`t`t<name>$($siteLink.Name)</name>`n"
	$places += "`t`t`t<description></description>`n"
	$places += "`t`t`t<LineString>`n"
	$places += "`t`t`t`t<coordinates>"
	
	$locations = Get-SiteCoordinates($siteLink.SiteList)
	$places += $locations + "`n"
	
	$places += "`t`t`t`t</coordinates>`n"
	$places += "`t`t`t</LineString>`n"
	$places += "`t`t</Placemark>`n"
}

# Substitute in the XML of our Placemarks into a placeholder string in the KML.
$places = $places.Substring(0,$places.Length - 1)
$kml = $kml -replace "{PLACEMARKS}", $places
$kml | Set-Content -Path $kmlFile