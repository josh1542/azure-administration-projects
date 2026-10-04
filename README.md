# Azure Administration Portfolio

Hands-on Microsoft Azure administration portfolio built while preparing for Microsoft AZ-104.

This repository documents practical Azure labs and larger projects covering identity, automation, compute, storage, networking, governance, monitoring and recovery. Terraform is included where it adds practical value, alongside ARM Templates, Bicep, PowerShell and Microsoft Graph.

## Hands-on Azure Labs

### [01. Azure Cost Management Budget and Alerts](configurations/01-cost-management-budget/README.md)

Configured Azure Cost Management budgets, actual and forecasted thresholds, Action Group notifications and a Terraform equivalent.

### [02. Microsoft Entra ID Users and Groups](configurations/02-identity-and-governance/README.md)

Created internal and guest identities, security groups and group memberships in Microsoft Entra ID.

### [03. Azure RBAC with Entra Groups](configurations/03-azure-rbac/README.md)

Implemented group-based Azure RBAC with the Virtual Machine Contributor role at resource-group scope.

### [04. Azure Storage Security, Access and Recovery](configurations/04-azure-storage-security-and-access/README.md)

Configured Blob Storage and Azure Files with Entra RBAC, SAS access, snapshots, lifecycle management, Object Replication and Terraform.

### [05. Azure Virtual Machines, VMSS and Load Balancing](configurations/05-azure-virtual-machines/README.md)

Built and validated Azure VM, VM Scale Set, Load Balancer, monitoring, backup and Encryption at Host scenarios, including Terraform-based validation.

### [06. ARM Templates, Bicep and Terraform](configurations/06-arm-template-deployment/README.md)

Reproduced the same Azure managed-disk specification using the Azure Portal, ARM Templates, Bicep and Terraform.

### [07. Azure App Service, CI/CD and Deployment Slots](configurations/07-azure-app-service/README.md)

Deployed an Azure App Service workload with GitHub Actions CI/CD, deployment slots, autoscaling, VNet integration, TLS, backup and Terraform.

Related application repository: [az104-appservice-lab](https://github.com/josh1542/az104-appservice-lab)

### [08. Azure Container Registry, ACI and Container Apps](configurations/08-azure-containers/README.md)

Built a private container workflow with Azure Container Registry, Azure Container Instances, Azure Container Apps, managed identity, RBAC, ingress and scaling.

### [09. Cross-Region VNet Peering and VPN Gateway](configurations/09-azure-vnet-peering-and-gateway/README.md)

Implemented cross-region connectivity between Australia East and Australia Southeast using Global VNet Peering and a VNet-to-VNet VPN.

### [10. Azure Private DNS Across VNets](configurations/10-azure-dns-and-private-dns/README.md)

Configured a shared Azure Private DNS namespace across multiple VNets and validated private hostname resolution.

### [11. NSG and ASG Traffic Filtering](configurations/11-azure-network-security-groups/README.md)

Implemented and tested subnet-level Network Security Group filtering using Application Security Groups and explicit rule priorities.

### [12. Azure Application Gateway Load Balancing](configurations/12-azure-application-gateway/README.md)

Validated Layer 7 HTTP load balancing, backend health and traffic distribution with Azure Application Gateway.

### [13. Azure Monitor, Log Analytics and KQL](configurations/13-azure-monitor-and-log-analytics/README.md)

Built an Azure monitoring workflow using Azure Monitor, Log Analytics, Azure Monitor Agent, Data Collection Rules, VM Insights, KQL and alerts.

### [14. Azure VM Backup and Recovery](configurations/14-azure-backup-and-recovery/README.md)

Validated Azure VM protection, recovery points, file recovery, VM recovery and managed disk restore with Azure Backup and Terraform.

## Projects

### [01. Azure Policy, Governance and Resource Protection](projects/01-azure-governance-resource-protection/README.md)

Built and validated Azure governance controls using Policy, tagging, Modify remediation with managed identity, management-group hierarchy practice and resource locks.

The project includes deliberate non-compliance testing, successful policy enforcement, tag remediation and deletion-protection validation.

### [02. Entra User Lifecycle Automation](projects/02-entra-user-lifecycle-automation/README.md)

Built a PowerShell and Microsoft Graph workflow for Microsoft Entra user onboarding and offboarding.

The workflow covers user creation, profile configuration, temporary-password generation, security-group assignment, account disabling, sign-in session revocation, direct group removal, licence handling, final-state validation and audit logging.

A separate local Python and Ollama agent provides a dry-run interface for onboarding and offboarding requests, with identity validation and administrator approval controls.

## Implementation Approach

The portfolio follows a validation-focused workflow:

```text
Azure concept
   ↓
Hands-on implementation
   ↓
Security and configuration validation
   ↓
Real behaviour testing
   ↓
Infrastructure as Code where appropriate
   ↓
Evidence and documentation
```

The focus is not only on creating Azure resources, but on validating that they behave as intended.

Examples include:

- Validating and revoking Azure Storage access
- Recovering files, VMs and disks with Azure Backup
- Testing VM Scale Set autoscaling and Load Balancer distribution
- Validating private VPN connectivity and DNS resolution
- Confirming NSG Allow and Deny behaviour
- Testing Application Gateway backend health and traffic distribution
- Querying monitoring telemetry with KQL
- Deliberately triggering Azure Monitor alerts
- Importing existing Azure infrastructure into Terraform
- Validating Terraform-managed environments with no-drift plans
- Automating Microsoft Entra onboarding and offboarding with PowerShell and Microsoft Graph

## Infrastructure as Code and Automation

The portfolio uses:

- Terraform
- ARM Templates
- Bicep
- Azure CLI
- PowerShell
- Microsoft Graph
- Python
- Ollama
- GitHub Actions

Terraform is used where it adds practical value, while portal-based builds are retained where live validation or comparison is useful.

Terraform state, plan and working-directory files are excluded from source control.

## Security and Repository Practices

This repository is designed for public portfolio use.

Sensitive or environment-specific information is excluded where appropriate, including:

- Passwords
- Authentication tokens
- Storage account keys
- SAS tokens and URLs
- Personal email addresses
- Tenant and subscription IDs
- Unnecessary Azure resource identifiers
- Terraform state and plan files

Temporary Azure resources are removed after validation where practical to control cloud costs.