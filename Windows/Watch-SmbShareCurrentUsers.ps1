# Quick and dirty script to monitor the number of users connected to
# a hosts's SMB shares and output them with color coding as the
# number of users changes.

$previous = $null
$session = (New-CimSession -ComputerName server1)
while($true){

    $next = (Get-SmbShare -CimSession $session)
    Clear-Host
    if($previous -ne $null){
        # Compare next to latest and output the chart.
        $next | Sort-Object Name | ForEach-Object {
            $nextShare = $_
            $previousCount = ($previous | Where-Object { $_.Name -eq $nextShare.Name }).CurrentUsers
            Write-Host -NoNewline "$($nextShare.Name)`t"
            if($nextShare.CurrentUsers -eq $previousCount){
                Write-Host $nextShare.CurrentUsers
            }elseif($nextShare.CurrentUsers -gt $previousCount){
                Write-Host $nextShare.CurrentUsers -ForegroundColor Green
            }else{
                Write-Host $nextShare.CurrentUsers -ForegroundColor Red
            }
        }
    }else{
        # This is the first iteration.
        $next | Sort-Object Name | ForEach-Object {
            Write-Host "$($_.Name)`t$($_.CurrentUsers)"
        }
    }

    $previous = $next
    Start-Sleep -Seconds 5

}
Remove-CimSession $session
