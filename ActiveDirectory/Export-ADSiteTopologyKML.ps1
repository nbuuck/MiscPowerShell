<#
nbuuck _at_ gmail dot com 

PURPOSE: Produces a Keyhole Markup Language file representing an Active Directory
domain's Site topology.

REQUIREMENTS: Requires read access to the Configuration partition of the domain and
that the Location attribute of every Site contains a KML-compliant GPS coordinate.
#>

$filePath = "AD-SitesTopology.kml"
$kmlTemplate = ".\Template-ADSiteTopologyKML.xml"
$domain = $($Env:USERDNSDOMAIN)

Clear-Host
Import-Module ActiveDirectory

# FUNCTIONS
function Get-SiteCoordinates($siteList){
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
if($domain -eq $null) {
	Write-Error "This computer does not belong to a domain."
	return
}
$domain = $domain.Split(".")
foreach($subdomain in $domain){
	$dnSuffix += "DC=$subdomain,"
}
$dnSuffix = $dnSuffix.TrimEnd(',')

# Build search bases for Containers with Site information.
$sitesSearchBase = "CN=Sites,CN=Configuration,$dnSuffix"
$siteLinksBase = "CN=IP,CN=Inter-Site Transports,$sitesSearchBase"
$subnetsBase = "CN=Subnets,CN=Sites,CN=Configuration,$dnSuffix"

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
$kml = Get-Content $kmlTemplate
$places = ""

# Represent each Site as a single-point Placemark.
foreach($site in $sites){
	$serversBase = "CN=Servers,$($site.DistinguishedName)"
	$servers = Get-ADObject `
		-SearchBase $serversBase `
		-Filter { objectClass -eq "server" }
	$subnets = Get-ADObject `
		-SearchBase $subnetsBase `
		-Filter { objectClass -eq "subnet" -and siteObject -eq $site.DistinguishedName } `
		| Sort-Object Name
	
	$places += "`t`t<Placemark>`n"
	$desc = ""
	
	# List site domain controllers in the description.
	# TODO: Include as array of elements in ExtendedData.
	if($servers -ne $null){
		$places += "`t`t`t<styleUrl>#site-with-dc</styleUrl>`n"
		$serverList = ""
		$servers | ForEach-Object { $serverList += "$($_.Name)," }
		$serverList = $serverList.TrimEnd(",")
		$desc += "Domain Controllers: $serverList"
	}else{
		$places += "`t`t`t<styleUrl>#site-without-dc</styleUrl>`n"
	}
	
	# List site subnets in the description.
	# TODO: Include as array of elements in ExtendedData.
	if($subnets -ne $null){
		$desc += "`n`t`t`t`tSUBNETS:`n"
		foreach($subnet in $subnets){
			$desc += "`t`t`t`t$($subnet.Name)`n"
		}
	}	
	
	$places += "`t`t`t<name>$($site.Name)</name>`n"
	$places += "`t`t`t<description>$desc</description>`n"
	$places += "`t`t`t<Point>`n"
	$places += "`t`t`t`t<coordinates>$($site.Location),0.0</coordinates>`n"
	$places += "`t`t`t</Point>`n"
	$places += "`t`t</Placemark>`n"
}

# Represent each Site Link as a LineString.
# Only tested with SiteLinks having only two Sites per link.
foreach($siteLink in $siteLinks){
	$places += "`t`t<Placemark>`n"
	$places += "`t`t`t<styleUrl>#site-link</styleUrl>`n"
	$places += "`t`t`t<name>$($siteLink.Name)</name>`n"
	$places += "`t`t`t<description>Cost: $($siteLink.Cost)`n"
	$places += "`t`t`t`tInterval: $($siteLink.ReplInterval)m</description>`n"
	$places += "`t`t`t<LineString>`n"
	$places += "`t`t`t`t<coordinates>"
	
	$locations = Get-SiteCoordinates($siteLink.SiteList)
	$places += $locations + "`n"
	
	$places += "`t`t`t`t</coordinates>`n"
	$places += "`t`t`t</LineString>`n"
	$places += "`t`t</Placemark>`n"
}

# Substitute in the XML of our Placemarks into a placeholder string in the KML.
$places = $places.TrimEnd("`n")
$kml = $kml -replace "{PLACEMARKS}", $places

# Use Set-Content so file is ANSI or Maps won't import.
$kml | Set-Content -Path $filePath