# Enterprise Azure Landing Zone with IaC & Governance

## Overview
Automated deployment of a compliant, scalable Hub-and-Spoke Azure Landing Zone using Terraform, designed for UK regulated financial services.

## Architecture Highlights
- **Hub VNet (`10.0.0.0/16`)**: Dedicated subnets for centralized management and shared services.
- **Spoke VNet (`10.1.0.0/16`)**: Tier-segmented workloads (Web, App, Data) interconnected via bidirectional VNet Peering.
- **Security & Secrets**: Azure Key Vault provisioned with purge protection and soft-delete retention.
- **Governance**: Azure Policy enforcing UK-only regions and mandatory tagging (`Environment`, `CostCentre`, `Owner`).
- **Cost Controls**: Azure Budget notifications configured at 80% and 100% thresholds; Log Analytics workspace for unified telemetry.

## Deployment Steps
1. `az login`
2. `terraform init`
3. `terraform plan -out=tfplan`
4. `terraform apply tfplan`
