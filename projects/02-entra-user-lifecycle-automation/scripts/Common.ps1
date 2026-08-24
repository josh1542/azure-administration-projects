Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop
Import-Module Microsoft.Graph.Users.Actions -ErrorAction Stop

$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:LogDirectory = Join-Path $script:ProjectRoot "logs"
$script:AuditLogPath = Join-Path $script:LogDirectory "lifecycle-audit.csv"

function Write-LifecycleAudit {

    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory)]
        [ValidateSet("Success", "Failed", "Skipped")]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Details
    )

    if (-not (Test-Path $script:LogDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $script:LogDirectory `
            -Force |
            Out-Null
    }

    $AuditEntry = [PSCustomObject]@{
        Timestamp         = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
        Action            = $Action
        UserPrincipalName = $UserPrincipalName
        Status            = $Status
        Details           = $Details
    }

    $AuditEntry |
        Export-Csv `
            -Path $script:AuditLogPath `
            -Append `
            -NoTypeInformation
}


function Connect-UserLifecycleGraph {

    param(
        [Parameter(Mandatory)]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [string]$TenantId
    )

    $Scopes = @(
        "User.Read.All",
        "User.ReadWrite.All",
        "User.EnableDisableAccount.All",
        "GroupMember.ReadWrite.All",
        "LicenseAssignment.ReadWrite.All"
    )

    Write-Host ""
    Write-Host "Connecting to Microsoft Graph..."

    Set-MgGraphOption -DisableLoginByWAM $true

    Connect-MgGraph `
        -ClientId $ClientId `
        -TenantId $TenantId `
        -Scopes $Scopes `
        -ContextScope Process `
        -NoWelcome

    $Context = Get-MgContext

    if (-not $Context) {
        throw "Microsoft Graph connection failed."
    }

    try {
        $CurrentUser = Invoke-MgGraphRequest `
            -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/me"

        Write-Host ""
        Write-Host "Microsoft Graph connection successful."
        Write-Host "Signed in as:   $($CurrentUser.userPrincipalName)"
        Write-Host "Authentication: $($Context.AuthType)"
        Write-Host ""
    }
    catch {
        throw "Microsoft Graph authentication succeeded, but the validation request failed: $($_.Exception.Message)"
    }
}


function Resolve-UserLifecycleGroups {

    param(
        [Parameter(Mandatory)]
        [string[]]$GroupNames
    )

    $ResolvedGroups = @()

    foreach ($GroupName in $GroupNames) {

        $EscapedGroupName = $GroupName.Replace("'", "''")

        $Groups = @(
            Get-MgGroup `
                -Filter "displayName eq '$EscapedGroupName'" `
                -Property Id,DisplayName
        )

        if ($Groups.Count -eq 0) {
            throw "Group '$GroupName' was not found."
        }

        if ($Groups.Count -gt 1) {
            throw "Multiple groups named '$GroupName' were found."
        }

        $ResolvedGroups += $Groups[0]
    }

    return $ResolvedGroups
}


function Add-UserToGroups {

    param(
        [Parameter(Mandatory)]
        [string]$UserId,

        [Parameter(Mandatory)]
        [string]$UserPrincipalName,

        [Parameter(Mandatory)]
        [object[]]$Groups
    )

    foreach ($Group in $Groups) {

        $ExistingMember = Get-MgGroupMember `
            -GroupId $Group.Id `
            -All |
            Where-Object {
                $_.Id -eq $UserId
            }

        if ($ExistingMember) {

            Write-Host "User is already a member of: $($Group.DisplayName)"

            Write-LifecycleAudit `
                -Action "GroupAssignment" `
                -UserPrincipalName $UserPrincipalName `
                -Status "Skipped" `
                -Details "Already a member of $($Group.DisplayName)"

            continue
        }

        New-MgGroupMemberByRef `
            -GroupId $Group.Id `
            -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$UserId"

        Write-Host "Added user to: $($Group.DisplayName)"

        Write-LifecycleAudit `
            -Action "GroupAssignment" `
            -UserPrincipalName $UserPrincipalName `
            -Status "Success" `
            -Details "Added to $($Group.DisplayName)"
    }
}