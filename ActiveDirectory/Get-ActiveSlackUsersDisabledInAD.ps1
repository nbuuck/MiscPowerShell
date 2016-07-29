# Request a test token at https://api.slack.com/docs/oauth-test-tokens
# These shouldn't be used for production but are probably okay for this script's purpose... maybe.
$apiToken = "xxxx-xxxxxxxxxx-xxxxxxxxxxx-xxxxxxxxxxx-xxxxxxxxxx"

# Get all Slack users in our team.
$usersListApi = "https://slack.com/api/users.list?token=$apiToken"
$list = (Invoke-RestMethod $usersListApi | ConvertFrom-Json)

# Get a list of disabled AD users.
Import-Module ActiveDirectory
$disabledADUsers = (Search-ADAccount -AccountDisabled -UsersOnly | Get-ADUser -Properties mail)

# Get a list of all mail addresses on AD User objects.
$adUserEmailAddrs = @()
Get-ADUser -LDAPFilter "(mail=*)" -Properties mail,proxyAddresses | `
    ForEach-Object { `
        $adUserEmailAddrs += $_.mail; `
        foreach($addr in $_.proxyAddresses){ $adUserEmailAddrs += $addr } `
    }

$errors = @()

foreach($slackUser in $list.members){

    # Check if the Slack user is disabled in our AD....
    foreach($disabledADUser in $disabledADUsers){

        # ... and if the email address on both objects aren't null.
        if($disabledADUser.mail -ne $null `
            -and $slackUser.profile.email -ne $null){

            # ... and their lowercase forms are the same.
            # ... but the user isn't disabled in Slack.
            if($disabledADUser.mail.ToLower() -eq $slackUser.profile.email.ToLower() `
                -and -not $slackUser.deleted){

                $errors += "Disabled AD user $($disabledADUser.mail) is not deleted in Slack."

            } # endif
        
        } # endif

    } # foreach disabled AD user.

    # Check for Slack user's email address in our AD.
    if($slackUser.profile.email -ne $null){

        # If the Slack user's email address isn't somewhere in our AD, that's bad.
        if(-not $adUserEmailAddrs -contains $slackUser.profile.email -and -not $slackUser.deleted){

            $errors += "Slack user $($slackUser.profile.email) is not in our Active Directory."

        } #endif

    } #endif

} # foreach Slack member.

# Email if more than one error.
if($errors.Length -gt 0){

    $smtpServer = "smtp.domain.com"
    $msg = New-Object Net.Mail.MailMessage
    $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
    $msg.From = "donotreply@domain.com"
    $msg.ReplyTo = "donotreply@domain.com"
    $msg.To.Add("alias@domain.com")
    $msg.Subject = "$($Env:COMPUTERNAME) - Slack User Compliance Errors"
    $msg.Body = $errors
    $msg.IsBodyHtml = $false
    $smtp.Send($msg)

}
