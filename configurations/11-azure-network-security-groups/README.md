# NSG and ASG Traffic Filtering

## Overview

I built and validated Azure network traffic filtering using **Network Security Groups (NSGs)** and **Application Security Groups (ASGs)**.

The lab used workload-based security rules to allow HTTP traffic from an admin workload to a web workload while denying broader Virtual Network access to TCP/80. The core security architecture was then recreated with Terraform.

## Architecture

```text
vnet-security-lab
10.50.0.0/16

├── snet-admin
│   └── vm-admin
│       └── NIC → asg-admin
│
└── snet-web
    ├── nsg-web
    │   ├── Priority 100
    │   │   Allow TCP/80
    │   │   asg-admin → asg-web
    │   │
    │   └── Priority 110
    │       Deny TCP/80
    │       VirtualNetwork → asg-web
    │
    └── vm-web
        └── NIC → asg-web
```

## What I Configured

### Virtual Network Segmentation

Created an Azure virtual network with two workload subnets:

- `snet-admin` — `10.50.1.0/24`
- `snet-web` — `10.50.2.0/24`

The separation allowed the admin and web workloads to be grouped independently for security-rule testing.

### Application Security Groups

Created two Application Security Groups:

- `asg-admin`
- `asg-web`

The `vm-admin` network interface was associated with `asg-admin`, while the `vm-web` network interface was associated with `asg-web`.

This allowed NSG rules to reference workload roles instead of hard-coded IP addresses.

### Network Security Group

Created `nsg-web` and associated it with the `snet-web` subnet.

Two custom inbound rules were configured:

```text
Priority 100
allow-http-admin-to-web
TCP/80
asg-admin → asg-web
Allow
```

```text
Priority 110
deny-http-vnet-to-web
TCP/80
VirtualNetwork → asg-web
Deny
```

Azure processes NSG rules from the lowest numeric priority value to the highest and stops when traffic matches a rule.

This allowed the specific priority-100 rule to permit HTTP traffic from `asg-admin` before the broader priority-110 deny rule was evaluated.

### Allow Rule Validation

A lightweight HTTP service was started on `vm-web`.

From `vm-admin`, an HTTP request to the private IP of `vm-web` succeeded while `vm-admin` was a member of `asg-admin`.

This validated the priority-100 rule:

```text
asg-admin → asg-web
TCP/80
Allow
```

### Deny Rule Validation

`vm-admin` was temporarily removed from `asg-admin` and the same HTTP request was repeated.

The request timed out, confirming that the priority-100 Allow rule no longer matched and that the priority-110 rule blocked the traffic:

```text
VirtualNetwork → asg-web
TCP/80
Deny
```

The original `asg-admin` membership was then restored.

### Effective Security Rules

Reviewed the effective security rules for the `vm-web` network interface in the Azure Portal.

The calculated rule set showed:

- Priority `100` — `allow-http-admin-to-web`
- Priority `110` — `deny-http-vnet-to-web`
- Azure default inbound rules including `AllowVnetInBound`, `AllowAzureLoadBalancerInBound` and `DenyAllInBound`

This confirmed the NSG rules applying to the web workload through the `snet-web` subnet.

## Terraform Implementation

The security architecture was recreated with Terraform using the AzureRM provider.

Terraform defines **14 Azure resources**:

- 1 resource group
- 1 virtual network
- 2 subnets
- 2 Application Security Groups
- 1 Network Security Group
- 2 NSG security rules
- 1 subnet-to-NSG association
- 2 network interfaces
- 2 NIC-to-ASG associations

The Terraform version intentionally uses lightweight network interfaces rather than recreating the two VMs because the runtime allow/deny behaviour was already validated in the Azure Portal environment.

A final Terraform plan confirmed that the Terraform-managed infrastructure matched the configuration with no drift.

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

- Test VMs had no public IP addresses
- No public inbound ports were opened
- The NSG was applied at subnet scope to protect the web subnet
- ASGs were used to reference workload roles instead of fixed private IP addresses
- A specific Allow rule was evaluated before a broader Deny rule through explicit priority values
- Terraform state, plan and working-directory files were excluded from source control
- Temporary Azure resources were destroyed after validation to control cost

## Evidence

### NSG Priority Rules

![NSG priority rules](screenshots/nsg-priority-rules.png)

The custom priority-100 Allow and priority-110 Deny rules are shown alongside Azure's default inbound rules.

### Allow Validation

![NSG allow validation](screenshots/nsg-allow-validation.png)

`vm-admin` successfully reached the HTTP service on `vm-web` while the admin VM was a member of `asg-admin`.

### Deny Validation

![NSG deny validation](screenshots/nsg-deny-validation.png)

After removing `vm-admin` from `asg-admin`, the same TCP/80 request timed out as expected.

### Effective Security Rules

![Effective security rules](screenshots/effective-security-rules.png)

The effective rules for the `vm-web` network interface show the custom NSG rules and Azure default rules applying to the workload.

### Terraform-Managed Resources

![Terraform managed resources](screenshots/terraform-managed-resources.png)

Terraform state shows the full set of 14 managed networking and security resources.

## Key Skills

- Azure Network Security Groups
- NSG rule priorities
- Application Security Groups
- Subnet-level NSG associations
- Effective security rules
- Private network traffic filtering
- Allow and deny validation
- Azure Virtual Networks and subnets
- Linux HTTP connectivity testing
- Terraform Infrastructure as Code
- Terraform state and no-drift validation
- Azure security troubleshooting

## Result

Validated application-aware network segmentation with NSGs and ASGs by allowing HTTP traffic from the admin workload while denying broader Virtual Network access to the web workload.

The core security architecture was also reproduced with Terraform using subnet-level NSG enforcement and NIC-to-ASG associations.