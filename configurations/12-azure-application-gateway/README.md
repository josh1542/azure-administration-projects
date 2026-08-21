# Azure Application Gateway Load Balancing

## Overview

I built and validated Layer 7 HTTP load balancing with **Azure Application Gateway**.

The live Azure Portal environment used two private backend web servers to validate backend health and traffic distribution. I then recreated the core Application Gateway architecture with Terraform using lightweight backend network interfaces.

## Architecture

```text
Internet
   ↓
Public IP
   ↓
Azure Application Gateway
Standard_v2
HTTP listener :80
   ↓
Routing rule
   ↓
Backend HTTP settings :80
   ↓
Backend pool
   ├── vm-web-1
   └── vm-web-2
```

The Application Gateway used a dedicated subnet:

```text
vnet-appgw-lab
10.60.0.0/16

├── snet-appgw
│   └── 10.60.0.0/24
│
└── snet-backend
    └── 10.60.1.0/24
        ├── vm-web-1
        └── vm-web-2
```

## What I Configured

### Application Gateway Network Design

Created a dedicated Application Gateway subnet:

```text
snet-appgw
10.60.0.0/24
```

Backend workloads were isolated in a separate subnet:

```text
snet-backend
10.60.1.0/24
```

### Backend Web Servers

Created two Ubuntu backend VMs with no public IP addresses.

Each VM served a different HTTP response:

```text
vm-web-1 → Backend server 1
vm-web-2 → Backend server 2
```

This made it possible to verify that requests were reaching both backend targets.

### Application Gateway

Configured:

- `Standard_v2` Application Gateway
- Public frontend IP
- HTTP listener on port 80
- Basic routing rule
- Backend pool containing both web VMs
- Backend HTTP settings on port 80
- Autoscaling from 0–2 instances

### Backend Health Validation

Application Gateway Backend Health reported both backend servers as **Healthy**.

Both targets returned successful HTTP 200 responses to the gateway health checks.

### Traffic Distribution Validation

Repeated HTTP requests were sent to the Application Gateway public frontend.

The responses alternated between:

```text
Backend server 1
Backend server 2
```

This confirmed that Application Gateway was distributing HTTP traffic across both healthy backend servers.

## Terraform Implementation

The core Application Gateway architecture was recreated with Terraform using the AzureRM provider.

Terraform defines **8 Azure resources**:

- 1 resource group
- 1 virtual network
- 2 subnets
- 1 Standard public IP address
- 2 backend network interfaces
- 1 Application Gateway

The Terraform version intentionally uses lightweight backend NICs with static private IP addresses rather than recreating the two backend VMs. Live backend health and HTTP traffic distribution were already validated in the Azure Portal environment.

The Application Gateway backend pool references the two NIC private IP addresses:

```text
10.60.1.4
10.60.1.5
```

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

- Backend VMs in the live validation environment had no public IP addresses
- Application Gateway used a dedicated subnet
- Backend workloads were separated into their own subnet
- Only the Application Gateway frontend was publicly reachable in the live validation environment
- Backend health was validated before traffic testing
- Terraform state, plan and working-directory files were excluded from source control
- Temporary Azure resources were destroyed after validation to control cost

## Evidence

### Backend Health

![Application Gateway backend health](screenshots/application-gateway-backend-health.png)

Both backend servers were reported as Healthy and returned HTTP 200 responses.

### Traffic Distribution

![Application Gateway traffic distribution](screenshots/application-gateway-traffic-distribution.png)

Repeated requests to the Application Gateway public IP returned responses from both backend servers.

### Terraform-Managed Resources

![Terraform managed resources](screenshots/terraform-managed-resources.png)

Terraform state shows the complete set of 8 managed Application Gateway and networking resources.

## Key Skills

- Azure Application Gateway
- Layer 7 HTTP load balancing
- Public frontend IP configuration
- HTTP listeners
- Backend pools
- Backend HTTP settings
- Routing rules
- Backend health monitoring
- Traffic distribution validation
- Dedicated Application Gateway subnets
- Azure Virtual Networks and subnets
- Terraform Infrastructure as Code
- Terraform state and no-drift validation
- Azure resource cleanup and cost control

## Result

Validated Layer 7 HTTP load balancing across two private backend web servers with Azure Application Gateway, including backend health and live traffic distribution.

The core gateway and networking architecture was also reproduced with Terraform using lightweight backend NICs and static private IP targets.
