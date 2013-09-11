<#
.SYNOPSIS
Recursively attempts to index the child folders of a path. A potential use case is to run the script as a backup appliance's service account to verify that all files can be found.
#>

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true,HelpMessage="The path to test for readability.")]
	[String]$Path = "/",
	[Parameter(Mandatory=$false,HelpMessage="The file the results of the tests to.")]
	[String]$LogFile="Test-ChildPaths.log"
)

function TestPath($p) {
	try {
		Get-ChildItem $p -ea stop | ForEach-Object { 
			$fp = $_.FullName
			if($_.GetType().ToString() -eq "System.IO.DirectoryInfo") {
				TestPath($_.FullName)
			}
		}
	} catch{
		Write-Verbose "FAILURE Directory `"$p`""
		if(-not $PSBoundParameters['Verbose'] -eq $null) {
			Add-Content $LogFile "FAILURE Directory `"$p`""
		}
	}
}

CLS
Write-Verbose "Results will not be written to $LogFile because running as verbose."
TestPath($Path)