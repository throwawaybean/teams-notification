##version control 1.0


#Teams webhook url
$uri = "https://outlook.office.com/webhook/78e248f4-8d1b-4d68-bbc2-e9b95708872c@d98df7c0-89e7-46f8-b7ab-72fe1f6d821f/IncomingWebhook/00c207a940594792b4ed6f4371414cec/2c26f425-c3e1-4010-be83-ff0a9f39a892"

#Image on the left hand side, here I have a regular user picture
$ItemImage = 'https://img.icons8.com/color/1600/circled-user-male-skin-type-1-2.png'

#Get the date.time object for XX days ago
$5Days = (get-date).adddays(-3)

$NewUsersTable = New-Object 'System.Collections.Generic.List[System.Object]'
$ArrayTable = New-Object 'System.Collections.Generic.List[System.Object]'


Get-ADUser -SearchBase 'OU=SGP_Campus,DC=insead,DC=org' -Properties * -filter {whenCreated -ge $5Days -AND (enabled -eq $true) } | ForEach-Object{
	Write-Host "Working on $($_.Name)" -ForegroundColor White
	
	$WhenCreated = $_.WhenCreated
	$Today = (GET-DATE)
	
	
	$DaysSince = ((NEW-TIMESPAN –Start $WhenCreated –End $Today).Days).ToString() + " Days ago"
	
	$obj = [PSCustomObject]@{
		
		'Name' = $_.name
		'WhenCreated' = (($_.WhenCreated).ToShortDateString())
		'EmailAddress' = $_.emailaddress
		'Manager' = $_.Manager -replace '^CN=|,.*$'
        'Title' = $_.Title
		'Department' = $_.Department
		'SamAccountName' = $_.SamAccountName
	}
	

	$NewUsersTable.Add($obj)
}
Write-Host "New users $($($NewUsersTable).count)"


$NewUsersTable | ForEach-Object {
	
	$Section = @{
		activityTitle = "$($_.Name)"
		activitySubtitle = "$($_.EmailAddress)"
		activityText  = "$($_.Name)'s department is $($_.Department)"
		activityImage = $ItemImage
		facts		  = @(
			@{
				name  = 'Created on:'
				value = $_.WhenCreated
			},
			@{
				name  = 'Manager:'
				value = $_.Manager
			},
			@{
				name  = 'Title:'
				value = $_.Title
			},
			@{
				name  = 'SamAccountName:'
				value = $_.SamAccountName
			}
		)
	}
	$ArrayTable.add($section)
}

$body = ConvertTo-Json -Depth 8 @{
	title = "New Users - Notification"
	text  = "There are $($ArrayTable.Count)  new users in Singapore since $($5Days.ToShortDateString())"
	sections = $ArrayTable
	
}
Write-Host "Sending new users account POST" -ForegroundColor Green
Invoke-RestMethod -uri $uri -Method Post -body $body -ContentType 'application/json'