**Modular Azure DevOps Pipeline Template

Enterprise-ready Azure DevOps YAML pipeline template implementing modular design, multi-environment deployments, and build-once deploy-many principles.

Overview

This repository demonstrates a production-style CI/CD architecture using:

Modular YAML templates (stages / jobs / steps separation)

Multi-environment deployments (Dev / QA / Prod)

Azure DevOps Variable Groups

Azure Key Vault integration

Azure Container Registry (ACR)

Service Connections for secure authentication

Immutable artifact versioning

Designed to reflect enterprise DevOps patterns aligned with AZ-400 best practices.

Architecture Principles

Build Once, Deploy Many

Docker image built in CI

Tagged with immutable build ID

Promoted across environments without rebuild

Environment Isolation

Dedicated variable groups per environment

Secure secret retrieval from Azure Key Vault

Controlled production approvals via ADO Environments

Modular YAML Design

Reusable stage templates

Reusable job templates

Reusable step templates

Separation of concerns for maintainability

Repository Structure
.azure/
│
├── pipelines/
│   ├── ci.yml
│   ├── cd-dev.yml
│   ├── cd-qa.yml
│   └── cd-prod.yml
│
├── templates/
│   ├── stages/
│   ├── jobs/
│   └── steps/
Security & Governance

No secrets stored in YAML

Azure Service Connections for authentication

Key Vault-backed Variable Groups

Environment approvals for production

Immutable container tagging for traceability

Key Capabilities Demonstrated

Multi-stage YAML pipelines

Infrastructure-aware CI/CD design

Secure secret management

Docker image lifecycle management

Enterprise pipeline modularisation

Purpose

This project serves as:

A reusable CI/CD foundation

A DevOps portfolio demonstration

Practical preparation aligned to AZ-400**
