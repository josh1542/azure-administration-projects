param(
    [Parameter(Mandatory)]
    [string]$FirstName,

    [Parameter(Mandatory)]
    [string]$LastName,

    [Parameter(Mandatory)]
    [string]$UserPrincipalName,

    [string]$JobTitle,

    [string]$Department,

    [string]$UsageLocation = "AU",

    [string[]]$GroupNames = @(
        "SG-All-Employees"
    )
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    $Context = Get-MgContext

    if (-not $Context) {
        throw "No Microsoft Graph connection found. Run Connect-UserLifecycleGraph first."
    }

    $DisplayName = "$FirstName $LastName"

    $MailNickname = (($FirstName + "." + $LastName) -replace '[^a-zA-Z0-9.]', '').ToLower()

    Write-Host ""
    Write-Host "Starting user onboarding..."
    Write-Host "Name:       $DisplayName"
    Write-Host "UPN:        $UserPrincipalName"
    Write-Host "Department: $Department"
    Write-Host ""

    $EscapedUserPrincipalName = $UserPrincipalName.Replace("'", "''")

    $ExistingUser = Get-MgUser `
        -Filter "userPrincipalName eq '$EscapedUserPrincipalName'" `
        -ErrorAction SilentlyContinue

    if ($ExistingUser) {
        throw "A user with UPN '$UserPrincipalName' already exists."
    }

    $ResolvedGroups = @()

    if ($GroupNames.Count -gt 0) {
        Write-Host "Validating target groups..."

        $ResolvedGroups = @(
            Resolve-UserLifecycleGroups `
                -GroupNames $GroupNames
        )

        Write-Host "Group validation completed."
        Write-Host ""
    }

    $TemporaryPassword = "Az!" + ([guid]::NewGuid().ToString("N").Substring(0,16)) + "9a"

    $PasswordProfile = @{
        Password                      = $TemporaryPassword
        ForceChangePasswordNextSignIn = $true
    }

    $UserParameters = @{
        AccountEnabled    = $true
        DisplayName       = $DisplayName
        GivenName         = $FirstName
        Surname           = $LastName
        MailNickname      = $MailNickname
        UserPrincipalName = $UserPrincipalName
        PasswordProfile   = $PasswordProfile
        UsageLocation     = $UsageLocation
    }

    if ($JobTitle) {
        $UserParameters["JobTitle"] = $JobTitle
    }

    if ($Department) {
        $UserParameters["Department"] = $Department
    }

    $NewUser = New-MgUser @UserParameters

    Write-Host "User created successfully."

    Write-LifecycleAudit `
        -Action "UserCreated" `
        -UserPrincipalName $NewUser.UserPrincipalName `
        -Status "Success" `
        -Details "Created account for $DisplayName"

    if ($ResolvedGroups.Count -gt 0) {

        Write-Host ""
        Write-Host "Assigning group memberships..."

        Add-UserToGroups `
            -UserId $NewUser.Id `
            -UserPrincipalName $NewUser.UserPrincipalName `
            -Groups $ResolvedGroups
    }

    Write-Host ""
    Write-Host "Onboarding completed successfully."
    Write-Host ""
    Write-Host "Display Name:   $($NewUser.DisplayName)"
    Write-Host "UPN:            $($NewUser.UserPrincipalName)"
    Write-Host "Job Title:      $JobTitle"
    Write-Host "Department:     $Department"
    Write-Host "Usage Location: $UsageLocation"
    Write-Host "Groups:         $($GroupNames -join ', ')"
    Write-Host ""
    Write-Host "The temporary password is returned in the result object."
    Write-Host "It is not written to the lifecycle audit log."
    Write-Host ""

    [PSCustomObject]@{
        DisplayName                      = $NewUser.DisplayName
        UserPrincipalName                = $NewUser.UserPrincipalName
        TemporaryPassword                = $TemporaryPassword
        MustChangePasswordAtNextSignIn   = $true
    }
}
catch {

    Write-LifecycleAudit `
        -Action "Onboarding" `
        -UserPrincipalName $UserPrincipalName `
        -Status "Failed" `
        -Details $_.Exception.Message

    Write-Error "User onboarding failed: $($_.Exception.Message)"
}