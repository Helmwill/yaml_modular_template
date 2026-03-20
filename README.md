# Modular Azure DevOps Pipeline Template

> Enterprise-ready Azure DevOps YAML pipeline template implementing modular design, multi-environment deployments and build-once deploy-many principles.

---

## Overview

This repository demonstrates a production-style CI/CD architecture using:

- Modular YAML templates (stages / jobs / steps separation)
- Multi-environment deployments (Dev / QA / Prod)
- Azure DevOps Variable Groups
- Azure Key Vault integration
- Azure Container Registry (ACR)
- Service Connections for secure authentication
- Immutable artifact versioning

Designed to reflect enterprise DevOps patterns aligned with **AZ-400** best practices.

---

## Architecture Principles

### Build Once, Deploy Many
- Docker image built in CI
- Tagged with immutable build ID
- Promoted across environments without rebuild

### Environment Isolation
- Dedicated variable groups per environment
- Secure secret retrieval from Azure Key Vault
- Controlled production approvals via ADO Environments

### Modular YAML Design
- Reusable stage templates
- Reusable job templates
- Reusable step templates
- Separation of concerns for maintainability

---

## Repository Structure

```
.azure/
│
├── pipelines/
│   ├── ci.yml
│   ├── cd-dev.yml
│   ├── cd-qa.yml
│   └── cd-prod.yml
│
└── templates/
    ├── stages/
    ├── jobs/
    └── steps/

terraform/                  ← Azure infrastructure (VNet, Key Vault, ACR, Container Apps, ADO agent pools)
```

The `terraform/` directory contains all infrastructure that backs these pipelines — see [`terraform/README.md`](terraform/README.md) for full details.

---

## Security & Governance

| Practice | Detail |
|---|---|
| No secrets in YAML | All secrets managed externally |
| Service Connections | Azure-native secure authentication |
| Key Vault-backed Variable Groups | Runtime secret injection |
| Environment approvals | Gate-controlled production deployments |
| Immutable container tagging | Full traceability per build |

---

## Key Capabilities Demonstrated

- Multi-stage YAML pipelines
- Infrastructure-aware CI/CD design
- Secure secret management
- Docker image lifecycle management
- Enterprise pipeline modularisation

---

## Purpose

This project serves as:

- A reusable CI/CD foundation
- A DevOps portfolio demonstration
- Practical preparation aligned to **AZ-400**

# Used Claude to create readme layout
