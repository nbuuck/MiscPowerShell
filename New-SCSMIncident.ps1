# The absolute minimal operations needed to create a new Incident in SCSM.

Import-Module SMlets

$IncidentClass = Get-SCSMClass -Name System.WorkItem.Incident

$Props = @{`
	Urgency='Low';`
	Impact='Low';`
	Title='Test';`
	Id="IR{0}";`
	Status='Active';`
	Priority=3;`
	Source='Email';`
	Classification='Other Problems';`
	TierQueue='Infrastructure Systems'`
};
$NewIncident = New-SCSMObject -Class $IncidentClass -PropertyHashtable $Props -Passthru
Write-Host Created $NewIncident.Id
