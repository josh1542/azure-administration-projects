# Azure Administration Portfolio

Hands-on Microsoft Azure administration portfolio developed as part of my Microsoft AZ-104 preparation.

The repository combines practical Azure administration with **Terraform Infrastructure as Code** where appropriate. Each configuration focuses on a specific Azure administration area, while projects combine multiple Azure services and governance controls into larger end-to-end environments.

## Portfolio Highlights

- Microsoft Entra ID identity and access administration
    
- Azure RBAC and least-privilege access
    
- Azure Storage security, recovery and replication
    
- Windows and Linux virtual machines
    
- VM Scale Sets and load balancing
    
- Azure networking, VPN, DNS, NSGs and Application Gateway
    
- Azure App Service and GitHub Actions CI/CD
    
- Azure Container Apps and managed identities
    
- Azure Monitor, Log Analytics and KQL
    
- Azure Backup and recovery validation
    
- ARM Templates, Bicep and Terraform
    
- Azure Policy, resource locks and governance
    

---

## Configurations

### [01 — Azure Cost Management Budget with Action Group](configurations/01-cost-management-budget/README.md)

Implemented subscription-level Azure cost monitoring with actual and forecasted budget thresholds, Azure Monitor Action Group notifications, and a Terraform equivalent.

**Key skills:** Azure Cost Management, budgets, Action Groups, cost alerts, Terraform.

---

### [02 — Microsoft Entra ID Identity and Group Management](configurations/02-identity-and-governance/README.md)

Created internal Member and external Guest identities and managed access through an Assigned Microsoft Entra security group.

**Key skills:** Microsoft Entra ID, identity administration, Guest users, security groups, group-based access.

---

### [03 — Azure Role-Based Access Control](configurations/03-azure-rbac/README.md)

Implemented group-based Azure RBAC using the **Virtual Machine Contributor** role at resource group scope and validated least-privilege access through Microsoft Entra group membership.

**Key skills:** Azure RBAC, Access Control (IAM), Entra groups, built-in roles, least privilege.

---

### [04 — Azure Storage Security and Access](configurations/04-azure-storage-security-and-access/README.md)

Implemented secure Azure Storage administration across Blob Storage and Azure Files using Microsoft Entra ID, RBAC, SAS, snapshots, lifecycle management, Object Replication and Terraform.

**Key skills:** Azure Storage, Blob Storage, Azure Files, RBAC, SAS, recovery, lifecycle management, Object Replication, Terraform.

---

### [05 — Azure Virtual Machines](configurations/05-azure-virtual-machines/README.md)

Built and administered Windows Azure compute workloads using Virtual Machines, managed disks, VM Scale Sets, autoscaling, Azure Load Balancer, monitoring, backup and security features.

Validated real traffic distribution across VMSS instances and deployed a separate Terraform-managed VM with **Encryption at Host** enabled.

**Key skills:** Azure VMs, Windows Server, VMSS, Load Balancer, autoscaling, Azure Monitor, Encryption at Host, Terraform.

---

### [06 — ARM Templates, Bicep and Terraform](configurations/06-arm-template-deployment/README.md)

Reproduced the same Azure managed-disk configuration using the Azure Portal, ARM Templates, Bicep and Terraform to compare multiple Infrastructure as Code approaches.

**Key skills:** ARM Templates, Bicep, Azure CLI, Terraform, managed disks, Infrastructure as Code.

---

### [07 — Azure App Service](configurations/07-azure-app-service/README.md)

Deployed and administered an Azure App Service workload covering application deployment, GitHub Actions CI/CD, deployment slots, autoscaling, VNet integration, TLS and backup configuration.

**Key skills:** Azure App Service, GitHub Actions, CI/CD, deployment slots, autoscale, VNet integration, Terraform.

#### Related Application Repository

[**az104-appservice-lab**](https://github.com/josh1542/az104-appservice-lab)

Contains the ASP.NET Core application and GitHub Actions workflow used to build and deploy the application to Azure App Service.

---

### [08 — Azure Containers](configurations/08-azure-containers/README.md)

Implemented a private container workflow using Azure Container Registry, Azure Container Instances and Azure Container Apps with managed identity-based ACR authentication, external ingress, revisions and scaling.

**Key skills:** ACR, ACI, Azure Container Apps, managed identities, Azure RBAC, AcrPull, ingress, scaling, Terraform.

---

### [09 — Azure VNet Peering and Gateway](configurations/09-azure-vnet-peering-and-gateway/README.md)

Implemented cross-region Azure networking between Australia East and Australia Southeast using Global VNet Peering and a VNet-to-VNet VPN.

Private VM-to-VM connectivity was validated across the VPN after removing the peering path, and the complete architecture was recreated with Terraform.

**Key skills:** Azure VNets, Global VNet Peering, VPN Gateway, VNet-to-VNet VPN, routing, private connectivity, Terraform.

---

### [10 — Azure DNS and Private DNS](configurations/10-azure-dns-and-private-dns/README.md)

Implemented Azure Private DNS across multiple virtual networks and validated bidirectional private hostname resolution using Linux `nslookup`.

**Key skills:** Azure Private DNS, DNS zones, A records, VNet links, private name resolution, Terraform.

---

### [11 — Azure Network Security Groups](configurations/11-azure-network-security-groups/README.md)

Implemented and validated Azure traffic filtering using Network Security Groups and Application Security Groups.

Testing confirmed both successful HTTP access and denied traffic based on NSG rule priority and ASG membership.

**Key skills:** NSGs, ASGs, security rules, rule priorities, effective security rules, traffic filtering, Terraform.

---

### [12 — Azure Application Gateway](configurations/12-azure-application-gateway/README.md)

Implemented Layer 7 HTTP load balancing using Azure Application Gateway with two private backend web servers.

Validated healthy backend targets and real HTTP traffic distribution across both servers.

**Key skills:** Azure Application Gateway, Layer 7 load balancing, backend pools, health probes, routing rules, Terraform.

---

### [13 — Azure Monitor and Log Analytics](configurations/13-azure-monitor-and-log-analytics/README.md)

Implemented an end-to-end Azure monitoring workflow using Azure Monitor, Log Analytics, Azure Monitor Agent, Data Collection Rules, VM Insights and KQL.

Validated guest telemetry and deliberately generated CPU load to trigger a custom Azure Monitor alert.

**Key skills:** Azure Monitor, Log Analytics, AMA, DCRs, VM Insights, KQL, alerts, Action Groups, Terraform.

---

### [14 — Azure Backup and Recovery](configurations/14-azure-backup-and-recovery/README.md)

Implemented and validated Azure VM backup and recovery using a Recovery Services vault, enhanced backup policy, recovery points, file recovery, VM recovery and managed disk restore.

The core backup environment was recreated with Terraform and validated through an on-demand backup and successful restore operation.

**Key skills:** Azure Backup, Recovery Services vaults, recovery points, file recovery, VM recovery, disk restore, Terraform, Azure PowerShell.

---

# Projects

## [01 — Azure Identity, Access and Governance](projects/01-azure-identity-access-governance/README.md)

Built an integrated Azure governance environment combining:

- Azure management-group hierarchy practice
    
- Resource tagging
    
- Azure Policy
    
- Deny policy enforcement
    
- Modify effects and remediation
    
- System-assigned managed identity
    
- Resource-group Delete lock
    
- Compliance testing
    
- Resource-protection validation
    

A deliberately non-compliant deployment was blocked by policy, a compliant resource was deployed successfully, missing tags were remediated automatically, and resource deletion was blocked by the configured lock.

**Key skills:** Azure governance, Azure Policy, policy enforcement, remediation, managed identities, management groups, tagging, resource locks.

---

# Implementation Approach

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
Terraform recreation where appropriate
   ↓
Portfolio evidence and documentation
```

The focus is not only on creating Azure resources, but on validating that they behave as intended.

Examples include:

- Triggering and revoking Azure Storage access
    
- Recovering files and VM disks from Azure Backup
    
- Testing VMSS autoscaling and Load Balancer distribution
    
- Validating private VPN connectivity and DNS resolution
    
- Confirming NSG Allow and Deny behaviour
    
- Testing Application Gateway backend health and traffic distribution
    
- Querying monitoring telemetry with KQL
    
- Deliberately triggering Azure Monitor alerts
    
- Importing existing Azure infrastructure into Terraform
    
- Validating final Terraform deployments with no-drift plans
    

---

# Infrastructure as Code

Terraform is used throughout the portfolio where it provides practical value.

Examples include:

- Azure Cost Management and Action Groups
    
- Azure Storage and Azure Files
    
- Azure RBAC and managed identities
    
- Virtual Machines and managed disks
    
- Azure Load Balancer
    
- Azure App Service
    
- Azure Container services
    
- Virtual Networks and VPN Gateways
    
- Azure Private DNS
    
- Network Security Groups and Application Security Groups
    
- Azure Application Gateway
    
- Azure Monitor and Log Analytics
    
- Azure Backup and Recovery
    

ARM Templates and Bicep are also included for Azure-native Infrastructure as Code comparison.

Terraform state, plan and working-directory files are excluded from source control.

---

# Security and Repository Practices

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
    

A repository-level `.gitignore` is used to exclude Terraform runtime and sensitive local files.

Temporary Azure resources are removed after validation where practical to control cloud costs.

---

# Technologies

`Microsoft Azure` · `Microsoft Entra ID` · `Azure RBAC` · `Azure Policy` · `Azure Storage` · `Azure Files` · `Azure Virtual Networks` · `Azure VPN Gateway` · `Azure Private DNS` · `Network Security Groups` · `Application Security Groups` · `Azure Virtual Machines` · `VM Scale Sets` · `Azure Load Balancer` · `Azure Application Gateway` · `Azure Monitor` · `Log Analytics` · `KQL` · `Azure Backup` · `Azure App Service` · `Azure Container Registry` · `Azure Container Instances` · `Azure Container Apps` · `Managed Identities` · `ARM Templates` · `Bicep` · `Terraform` · `Azure CLI` · `PowerShell` · `GitHub Actions`

---

# Current Status

- **14 focused Azure configurations completed**
    
- **1 integrated Azure governance project completed**
    
- Terraform included where appropriate
    
- Hands-on validation and evidence maintained alongside each configuration