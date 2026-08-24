param(
    [Parameter(Mandatory)]
    [string]$UserPrincipalName
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\Common.ps1"

try {
    $Context = Get-MgContext

    if (-not $Context) {
        throw "No Microsoft Graph connection found. Run Connect-UserLifecycleGraph first."
    }

    Write-Host ""
    Write-Host "Starting user offboarding..."
    Write-Host "UPN: $UserPrincipalName"
    Write-Host ""

    $User = Get-MgUser `
        -UserId $UserPrincipalName `
        -Property Id,DisplayName,UserPrincipalName,AccountEnabled,LicenseAssignmentStates

    Write-Host "User found: $($User.DisplayName)"
    Write-Host ""

    # Disable account
    if ($User.AccountEnabled) {

        Update-MgUser `
            -UserId $User.Id `
            -AccountEnabled:$false

        Write-Host "Account disabled."

        Write-LifecycleAudit `
            -Action "UserDisabled" `
            -UserPrincipalName $User.UserPrincipalName `
            -Status "Success" `
            -Details "Account disabled"
    }
    else {
        Write-Host "Account is already disabled."

        Write-LifecycleAudit `
            -Action "UserDisabled" `
            -UserPrincipalName $User.UserPrincipalName `
            -Status "Skipped" `
            -Details "Account was already disabled"
    }

    Write-Host ""

    # Revoke sign-in sessions
    $SessionsRevoked = Revoke-MgUserSignInSession `
        -UserId $User.Id `
        -Confirm:$false

    if (-not $SessionsRevoked) {
        throw "Microsoft Graph did not confirm sign-in session revocation."
    }

    Write-Host "Sign-in sessions revoked."

    Write-LifecycleAudit `
        -Action "SessionRevocation" `
        -UserPrincipalName $User.UserPrincipalName `
        -Status "Success" `
        -Details "Sign-in sessions revoked"

    Write-Host ""

    # Remove direct group memberships
    $Groups = @(
        Get-MgUserMemberOfAsGroup `
            -UserId $User.Id `
            -Property Id,DisplayName,GroupTypes `
            -All
    )

    if ($Groups.Count -gt 0) {

        Write-Host "Removing direct group memberships..."

        foreach ($Group in $Groups) {

            if ($Group.GroupTypes -contains "DynamicMembership") {

                Write-Host "Skipped dynamic group: $($Group.DisplayName)"

                Write-LifecycleAudit `
                    -Action "GroupRemoval" `
                    -UserPrincipalName $User.UserPrincipalName `
                    -Status "Skipped" `
                    -Details "Dynamic group: $($Group.DisplayName)"

                continue
            }

            Remove-MgGroupMemberByRef `
                -GroupId $Group.Id `
                -DirectoryObjectId $User.Id `
                -Confirm:$false

            Write-Host "Removed from: $($Group.DisplayName)"

            Write-LifecycleAudit `
                -Action "GroupRemoval" `
                -UserPrincipalName $User.UserPrincipalName `
                -Status "Success" `
                -Details "Removed from $($Group.DisplayName)"
        }
    }
    else {
        Write-Host "No direct group memberships found."

        Write-LifecycleAudit `
            -Action "GroupRemoval" `
            -UserPrincipalName $User.UserPrincipalName `
            -Status "Skipped" `
            -Details "No direct group memberships found"
    }

    Write-Host ""

    # Remove directly assigned licences
    $DirectLicenseSkuIds = @(
        $User.LicenseAssignmentStates |
            Where-Object {
                -not $_.AssignedByGroup -and $_.SkuId
            } |
            Select-Object -ExpandProperty SkuId -Unique
    )

    if ($DirectLicenseSkuIds.Count -gt 0) {

        Set-MgUserLicense `
            -UserId $User.Id `
            -AddLicenses @() `
            -RemoveLicenses $DirectLicenseSkuIds |
            Out-Null

        Write-Host "Direct licences removed."

        Write-LifecycleAudit `
            -Action "LicenseRemoval" `
            -UserPrincipalName $User.UserPrincipalName `
            -Status "Success" `
            -Details "Removed directly assigned licences"
    }
    else {
        Write-Host "No directly assigned licences found."

        Write-LifecycleAudit `
            -Action "LicenseRemoval" `
            -UserPrincipalName $User.UserPrincipalName `
            -Status "Skipped" `
            -Details "No directly assigned licences found"
    }

    Write-Host ""

    # Final validation
    $ValidatedUser = Get-MgUser `
        -UserId $User.Id `
        -Property DisplayName,UserPrincipalName,AccountEnabled

    $RemainingGroups = @(
        Get-MgUserMemberOfAsGroup `
            -UserId $User.Id `
            -Property Id,DisplayName,GroupTypes `
            -All |
            Where-Object {
                $_.GroupTypes -notcontains "DynamicMembership"
            }
    )

    Write-LifecycleAudit `
        -Action "OffboardingCompleted" `
        -UserPrincipalName $ValidatedUser.UserPrincipalName `
        -Status "Success" `
        -Details "AccountEnabled=$($ValidatedUser.AccountEnabled); RemainingGroups=$($RemainingGroups.Count)"

    Write-Host "Offboarding completed successfully."
    Write-Host ""
    Write-Host "Display Name:      $($ValidatedUser.DisplayName)"
    Write-Host "UPN:               $($ValidatedUser.UserPrincipalName)"
    Write-Host "Account Enabled:   $($ValidatedUser.AccountEnabled)"
    Write-Host "Remaining Groups:  $($RemainingGroups.Count)"
    Write-Host ""
}
catch {

    Write-LifecycleAudit `
        -Action "Offboarding" `
        -UserPrincipalName $UserPrincipalName `
        -Status "Failed" `
        -Details $_.Exception.Message

    Write-Error "User offboarding failed: $($_.Exception.Message)"
}