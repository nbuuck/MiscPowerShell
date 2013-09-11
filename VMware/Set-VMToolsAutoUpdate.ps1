<#
.SYNOPSIS
Set all VMs in a cluster to auto-update vmtools on power cycle.
#>

# http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1010048
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
$vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
$vmConfigSpec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"

$DATACENTER = "HQ Data Center"
$CLUSTERS = ("Prod Cluster")

ForEach ($Datacenter in (Get-Datacenter | Where { $_.Name -eq $DATACENTER })) {
	ForEach ($Cluster in ($Datacenter | Get-Cluster | Where { $CLUSTERS -Contains $_.Name } | Sort-Object -Property Name)) { 
		ForEach ($vm in ($Cluster | Get-VM | Sort-Object -Property Name)) {
			if($vm.ExtensionData.Config.Tools.ToolsUpgradePolicy.ToLower() -ne "upgradeatpowercycle") {
				$vmViewObject = $vm | Get-View
				Write-Host $Cluster"\"$vm
				$vmViewObject.ReconfigVM($vmConfigSpec)
			}
		}
	}
}

Write-Host "DONE!" -ForegroundColor Green