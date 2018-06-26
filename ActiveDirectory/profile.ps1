# A custom prompt to indicate whether a Domain Admin token is being used,
# if the host is locally elevated using a UNIX-like prompt tail, 
# and the computer name.

# about_Prompts
function prompt {

	# https://superuser.com/a/749259/917885
	$isElevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
	$isDomainAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "-512")
	
	Write-Host -NoNewLine -ForegroundColor Green ($Env:COMPUTERNAME + " ")
	Write-Host -NoNewLine -ForegroundColor Cyan $ExecutionContext.SessionState.Path.CurrentLocation
	
	if($isDomainAdmin){
		Write-Host -NoNewLine " "
		Write-Host -NoNewLine -BackgroundColor Red "DA"
	}
	
	$promptTail = '>'
	if($isElevated){
		$promptTail = '#'
	}
	
	"$($promptTail * ($nestedPromptLevel + 1)) "

}
