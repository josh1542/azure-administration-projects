# Azure Storage Security, Access and Recovery

## Overview

I configured and validated Azure Storage across identity-based access, delegated access, data protection, Azure Files, lifecycle management and Object Replication.

The lab was first built and tested through the Azure Portal, then recreated and extended with Terraform.

## Architecture

```text
Microsoft Entra ID
   ↓
Azure RBAC
   ↓
Azure Storage
├── Blob Storage
│   ├── Private Container
│   ├── SAS Access
│   ├── Soft Delete
│   ├── Versioning
│   ├── Lifecycle Management
│   └── Object Replication
│
└── Azure Files
    ├── Identity-Based Access
    ├── File Share
    ├── Snapshot
    └── Recovery
```

## What I Configured

### Identity and Blob Access

Configured a private Blob container with Microsoft Entra ID authentication and Azure RBAC.

The lab user was assigned:

- Reader
- Storage Blob Data Contributor

This separated management-plane visibility from data-plane access.

The user authenticated with Microsoft Entra ID and successfully uploaded data to the private container.

### Shared Access Signatures

Validated temporary delegated access using:

- User delegation SAS
- Service SAS
- Stored access policy

A service SAS linked to a stored access policy was tested successfully.

The stored access policy was then removed, invalidating the previously working SAS and demonstrating central revocation of delegated access.

### Storage Administration

Used both **AzCopy** and **Azure Storage Explorer** to upload and manage storage data.

This validated command-line and graphical administration methods in addition to the Azure Portal.

### Azure Files and Data Protection

Configured and validated:

- Identity-based Azure Files access
- File-share snapshots
- Snapshot recovery
- Azure Files soft delete
- Blob soft delete
- Blob versioning
- Blob change feed
- Lifecycle management

A file-share snapshot was successfully used during a recovery test.

### Object Replication

Configured Azure Blob Object Replication between source and destination containers.

A new test object was uploaded to the source container and appeared in the destination after asynchronous replication completed.

## Terraform Implementation

The core storage environment was recreated and extended with Terraform.

The current Terraform configuration defines **10 Azure resources**:

- 1 resource group
- 2 StorageV2 accounts
- 2 private Blob containers
- 2 Azure RBAC role assignments
- 1 lifecycle management policy
- 1 Azure Files share
- 1 Object Replication policy

The Terraform configuration also enables:

- HTTPS-only traffic
- TLS 1.2
- Private Blob container access
- Blob soft delete
- Container soft delete
- Azure Files soft delete
- Blob versioning
- Blob change feed
- Microsoft Entra authentication
- Azure Files identity-based authentication

Environment-specific values such as Microsoft Entra Object IDs and globally unique Storage account names are supplied through variables rather than hardcoded into the repository.

The initial Terraform deployment was validated with:

```text
Plan: 5 to add, 0 to change, 0 to destroy.
```

```text
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

The Terraform environment was then extended with Azure Files, lifecycle management and Object Replication.

### Terraform Files

```text
terraform/
├── .terraform.lock.hcl
├── main.tf
├── outputs.tf
├── providers.tf
├── variables.tf
└── versions.tf
```

## Security and Repository Practices

- Anonymous Blob access was disabled
- Secure transfer was required
- Minimum TLS version was set to TLS 1.2
- Microsoft Entra ID and Azure RBAC were used for identity-based access
- SAS tokens and full SAS URLs were excluded from public evidence
- Storage account access keys were not published
- Tenant IDs, subscription IDs, Microsoft Entra Object IDs and personal information were excluded from screenshots
- Environment-specific Terraform values were supplied through variables
- Terraform state, plan and working-directory files were excluded from source control
- Validation focused on actual access and data behaviour rather than only resource creation

## Evidence

### Azure RBAC Role Assignments

![Azure RBAC Role Assignments](screenshots/storage-rbac-role-assignments.png)

### Microsoft Entra Blob Access

![Microsoft Entra Blob Access](screenshots/storage-entra-rbac-access.png)

### SAS Revocation

![SAS Revocation](screenshots/storage-sas-revoked.png)

### AzCopy Upload

![AzCopy Upload](screenshots/azcopy-upload-success.png)

### Azure Storage Explorer

![Azure Storage Explorer](screenshots/azure-storage-explorer-upload.png)

### Azure Files Identity-Based Access

![Azure Files Identity-Based Access](screenshots/azure-files-identity-based-access.png)

### Azure Files Snapshot Recovery

![Azure Files Snapshot Recovery](screenshots/azure-files-snapshot-recovery.png)

### Blob Lifecycle Management

![Blob Lifecycle Management](screenshots/blob-lifecycle-management-rule.png)

### Blob Object Replication

![Blob Object Replication](screenshots/blob-object-replication-success.png)

### Terraform Deployment

![Terraform Apply](screenshots/terraform-apply.png)

### Terraform Microsoft Entra and RBAC Validation

![Terraform Microsoft Entra RBAC Upload](screenshots/terraform-storage-entra-rbac-upload-success.png)

### Terraform Azure Files

![Terraform Azure Files](screenshots/terraform-azure-files-identity-based-access.png)

### Terraform Lifecycle Management

![Terraform Lifecycle Management](screenshots/terraform-lifecycle-management-rule.png)

### Terraform Object Replication

![Terraform Object Replication](screenshots/terraform-object-replication-success.png)

## Key Skills

- Azure Storage
- Blob Storage
- Azure Files
- Microsoft Entra ID
- Azure RBAC
- Management-plane and data-plane permissions
- Shared Access Signatures
- User delegation SAS
- Stored access policies
- SAS revocation
- AzCopy
- Azure Storage Explorer
- Blob soft delete
- Azure Files soft delete
- Blob versioning
- Blob change feed
- File-share snapshots and recovery
- Lifecycle management
- Object Replication
- Terraform Infrastructure as Code
- Azure resource security and validation

## Result

Validated Azure Storage administration across identity, delegated access, data protection, file services, data transfer, lifecycle management and replication.

The core storage environment was reproduced and extended with Terraform, with identity-based access, Azure Files, lifecycle management and Object Replication validated through real data operations.