# Entra User Lifecycle Automation

## Overview

I built a PowerShell and Microsoft Graph workflow to automate common Microsoft Entra ID onboarding and offboarding tasks.

The project covers user creation, identity attributes, temporary-password generation, security-group assignment, account disabling, sign-in session revocation, direct group removal, direct licence-removal logic, final-state validation and lifecycle audit logging.

The workflow was developed against a Microsoft Entra ID lab tenant using PowerShell 7 and the Microsoft Graph PowerShell SDK.

## Architecture

```text
Administrator
     |
     v
PowerShell 7
     |
     v
Microsoft Graph
     |
     v
Microsoft Entra ID
     |
     +-- User Accounts
     +-- Security Groups
     +-- Licence Assignments
     +-- Sign-in Sessions
     +-- Account Status
```

Authentication uses a dedicated Microsoft Entra app registration with delegated Microsoft Graph permissions.

## Repository Structure

```text
02-entra-user-lifecycle-automation/
├── scripts/
│   ├── Common.ps1
│   ├── New-User.ps1
│   └── Offboard-User.ps1
├── screenshots/
│   ├── automated-user-validation.png
│   ├── automated-group-membership.png
│   ├── automated-offboarding-validation.png
│   └── lifecycle-audit-trail.png
├── logs/
│   └── lifecycle-audit.csv
├── .gitignore
└── README.md
```

Generated lifecycle audit CSV files are excluded from version control.

## Microsoft Graph Authentication

A dedicated Microsoft Entra app registration was created for the automation:

```text
Entra User Lifecycle Automation
```

The workflow requests the following delegated Microsoft Graph permissions:

```text
User.Read.All
User.ReadWrite.All
User.EnableDisableAccount.All
GroupMember.ReadWrite.All
LicenseAssignment.ReadWrite.All
```

Administrator consent was granted for the tenant-wide delegated permissions required by the workflow.

The helper function in `Common.ps1` establishes the Graph session with the application's client ID and tenant ID:

```powershell
. .\scripts\Common.ps1

Connect-UserLifecycleGraph `
    -ClientId "<application-client-id>" `
    -TenantId "<tenant-id>"
```

The onboarding and offboarding scripts require this Graph session to exist before they run.

No client secrets, access tokens or passwords are stored in the repository.

## User Onboarding

`scripts/New-User.ps1` automates user provisioning and initial account configuration.

The workflow performs:

```text
Validate Graph session
    |
    v
Check for existing UPN
    |
    v
Validate target groups
    |
    v
Generate temporary password
    |
    v
Create user
    |
    v
Require password change
    |
    v
Assign security groups
    |
    v
Write audit events
    |
    v
Return onboarding result
```

The script supports:

- First name
- Last name
- User principal name
- Display name
- Job title
- Department
- Usage location
- Security group membership

Example:

```powershell
$Result = .\scripts\New-User.ps1 `
    -FirstName "Emily" `
    -LastName "Carter" `
    -UserPrincipalName "emily.carter@contoso.onmicrosoft.com" `
    -JobTitle "IT Support Analyst" `
    -Department "Information Technology" `
    -GroupNames @(
        "SG-All-Employees",
        "SG-IT-Support"
    )
```

The temporary password is generated at runtime, the account is configured to require a password change at first sign-in, and the generated password is returned in the result object:

```powershell
$Result.TemporaryPassword
```

The temporary password is not written to the lifecycle audit log and should be handled through an appropriate secure handover process.

Target groups are validated before user creation so a missing or duplicate group name does not leave a newly created account in a partially configured onboarding state.

The completed lab validation used:

```text
SG-All-Employees
SG-IT-Support
```

## User Offboarding

`scripts/Offboard-User.ps1` automates access removal when a user leaves the organisation.

The workflow performs:

```text
Locate user
    |
    v
Disable account
    |
    v
Revoke sign-in sessions
    |
    v
Remove direct group memberships
    |
    v
Check direct licence assignments
    |
    v
Remove licences when applicable
    |
    v
Validate final account state
    |
    v
Write audit events
```

Example:

```powershell
.\scripts\Offboard-User.ps1 `
    -UserPrincipalName "emily.carter@contoso.onmicrosoft.com"
```

The existing lab evidence confirms:

```text
AccountEnabled = False
RemainingGroups = 0
```

Dynamic group memberships are skipped because they are controlled by Microsoft Entra membership rules rather than direct assignment.

The hardened offboarding script also calls `Revoke-MgUserSignInSession` after disabling the account so existing sign-in sessions are invalidated. This code hardening was added after the original screenshot validation, so the published screenshots should not be treated as evidence for that specific step.

## Security Group Automation

The onboarding workflow assigns users to predefined Entra security groups.

The project was tested with:

```text
SG-All-Employees
SG-IT-Support
```

Before account creation, each requested group is checked for:

- Missing groups
- Duplicate display names

After account creation, assignment logic checks for:

- Existing membership
- Successful assignment

During offboarding, direct non-dynamic group memberships are removed automatically.

## Licence Handling

The offboarding workflow checks the user's directly assigned licences.

If directly assigned licences are present, the script removes them through Microsoft Graph.

The lab tenant used for this project did not contain an assignable subscribed licence SKU, so the licence-removal branch could not be exercised against a live assigned licence.

The no-licence path was validated and records:

```text
LicenseRemoval
Skipped
No directly assigned licences found
```

No simulated licence assignment was used.

## Audit Logging

Lifecycle operations are recorded in:

```text
logs/lifecycle-audit.csv
```

Each audit record contains:

```text
Timestamp
Action
UserPrincipalName
Status
Details
```

Lifecycle events include:

```text
UserCreated
GroupAssignment
UserDisabled
SessionRevocation
GroupRemoval
LicenseRemoval
OffboardingCompleted
```

Generated CSV audit files are excluded from source control through `.gitignore`.

Temporary passwords are never written to the audit log.

## Error Handling and Validation

The scripts include checks for:

- Missing Microsoft Graph authentication context
- Existing users with the same UPN
- Missing security groups
- Duplicate group display names
- Existing group membership
- Dynamic security groups
- Direct licence assignments
- Sign-in session revocation
- Final account status
- Remaining direct group memberships

Failures are surfaced through PowerShell errors and relevant lifecycle failures are written to the audit log.

## Security and Repository Practices

- Dedicated Microsoft Entra app registration
- Delegated Microsoft Graph permissions scoped to the implemented operations
- Administrator consent for privileged delegated permissions
- No client secrets committed to Git
- No access tokens stored in source files
- Runtime temporary-password generation
- Password change required at first sign-in
- Temporary passwords excluded from audit logs
- Graph-session validation before lifecycle operations
- Target-group validation before user creation
- Sign-in session revocation during offboarding
- Generated audit logs excluded from version control
- Dynamic-group protection
- Final account-state validation

Tenant IDs, application client IDs and authentication material are not published in repository documentation or screenshots.

## Evidence

### Automated User Validation

The provisioned Entra user was validated through Microsoft Graph after creation.

The validation confirmed identity attributes including display name, user principal name, job title, department, usage location and enabled account state.

![Automated user validation](screenshots/automated-user-validation.png)

### Automated Group Membership

Microsoft Graph automation successfully assigned the user to the required Entra security groups.

![Automated group membership](screenshots/automated-group-membership.png)

### Automated Offboarding Validation

The original offboarding validation confirmed that the user account was disabled and direct security-group memberships were removed.

```text
AccountEnabled = False
RemainingGroups = 0
```

![Automated offboarding validation](screenshots/automated-offboarding-validation.png)

### End-to-End Lifecycle Audit Trail

The audit trail records the original validated lifecycle from account creation through group assignment and offboarding.

![Lifecycle audit trail](screenshots/lifecycle-audit-trail.png)

## Technologies Used

- Microsoft Entra ID
- Microsoft Graph
- Microsoft Graph PowerShell SDK
- PowerShell 7
- Microsoft Entra App Registrations
- Microsoft Entra Security Groups
- Git
- GitHub

## Key Skills

- Identity lifecycle automation
- Microsoft Graph administration
- PowerShell scripting
- Microsoft Entra ID administration
- User onboarding and offboarding
- Security group automation
- Microsoft Graph delegated permissions
- Administrative consent management
- Sign-in session revocation
- Audit logging
- Error handling and validation
- Secure credential handling
- Operational documentation

## Result

Built a reusable PowerShell and Microsoft Graph workflow for Microsoft Entra user onboarding and offboarding.

The original lab validation proved user creation, identity configuration, security-group assignment, account disabling, direct group removal, final-state validation and audit logging. The code was subsequently hardened with pre-creation group validation, explicit Graph-context validation, temporary-password handover and sign-in session revocation.

Direct licence-removal logic is implemented, while the live lab validated the no-licence path because an assignable licence SKU was not available.
