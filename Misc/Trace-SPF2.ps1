<#
.SYNOPSIS
Resolves the entire SPF TXT chain of a domain.
#>

[CmdletBinding()]
PARAM(

[Parameter(Mandatory=$True,
ValueFromPipeline=$True,
Position=0)]
[String]$Domain,

[Parameter(Mandatory=$False,
ValueFromPipeline=$False,
Position=1)]
[String]$NameServer="8.8.8.8"

)

BEGIN{ Clear-Host }

PROCESS{

Try{
Add-Type -TypeDefinition @"
	public enum SPFTokenType
	{
		ALL,
		A,
		IP4,
		IP6,
		MX,
		PTR,
		EXISTS,
		INCLUDE,
		EXP,
		REDIRECT,
		VERSION,
		UNKNOWN
	}
"@
}
Catch [System.Exception]{}

	function GetSPFTokenType($string){
		#Write-Verbose "GetSPFTokenType($string)"
		if($string -like "*all") { return [SPFTokenType]::ALL }
		if($string -like "a:*") { return [SPFTokenType]::A }
		if($string -like "ip4*") { return [SPFTokenType]::IP4 }
		if($string -like "ip6*") { return [SPFTokenType]::IP6 }
		if($string -like "mx*") { return [SPFTokenType]::MX }
		if($string -like "ptr*") { return [SPFTokenType]::PTR }
		if($string -like "exists*") { return [SPFTokenType]::EXISTS }
		if($string -like "include*") { return [SPFTokenType]::INCLUDE }
		if($string -like "exp*") { return [SPFTokenType]::EXP }
		if($string -like "redirect*") { return [SPFTokenType]::REDIRECT }
		if($string -like "v=*") { return [SPFTokenType]::VERSION }
		return [SPFTokenType]::UNKNOWN
	}

	function RecurseSPF(){
		PARAM(
			[String]$Name,
			[Int]$Depth
		)
				
		$tabs = ""
		for($i = 0; $i -lt $Depth; $i++){ $tabs += " " }
		Write-Host "$tabs$name"
		
		$txtRecords = (Resolve-DnsName -DnsOnly -Type TXT -Name $name -Server $NameServer)
		if($txtRecords -eq $null `
			-or $txtRecords.GetType() -eq "Microsoft.DnsClient.Commands.DnsRecord_SOA"){ 
			Write-Verbose "No TXT for $name. Skipping."
			continue
		}
		
		foreach($txtRecord in $txtRecords){
			
			foreach($string in $txtRecord.Strings){
				
				if($string.Length -lt 1 `
					-or $string.Substring(0,1) -ne "v") { continue }
				
				$parts = $string.ToString().Split(' ')				
				foreach($part in $parts) {
				
					$partType = GetSPFTokenType($part)
					
					if($partType -eq [SPFTokenType]::INCLUDE){
						$includeName = ($part | Select-String -Pattern ":(.*)").Matches[0].Groups[1].Value
						RecurseSPF -Name $includeName -Depth ($Depth+1)
					}elseif($partType -eq [SPFTokenType]::IP4){
						Write-Host "$tabs $part"
					}
					
				}
				
			}
			
		}
		
	}
	
	if($Domain.Substring($Domain.Length-1,1) -ne '.'){
		$Domain += '.'
	}
	
	RecurseSPF -Name $Domain -Depth 0
	
}

END{}