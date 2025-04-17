# Nomad on AWS Infrastructure

This repository contains Terraform configurations to deploy a Nomad cluster on AWS. The infrastructure is designed to use AWS Workload Identity for federating to AWS IAM using STS (Security Token Service). This enables secure and scalable authentication for workloads running on Nomad.

## Features

- **VPC Setup**: Creates a Virtual Private Cloud (VPC) with public and private subnets, NAT Gateway, and route tables.
- **Nomad Cluster**: Deploys a Nomad cluster with auto-scaling groups for servers and clients, using Bottlerocket AMIs for enhanced security and performance.
- **Workload Identity**: Configures an OpenID Connect (OIDC) provider to enable Nomad workloads to assume AWS IAM roles via STS.
- **Load Balancer**: Sets up an Application Load Balancer (ALB) for Nomad UI with HTTPS support using an ACM certificate.
- **API Gateway**: Deploys an API Gateway to expose OIDC endpoints for Nomad workloads.
- **DNS Management**: Configures public and private Route 53 hosted zones for domain name resolution.
- **Security Groups**: Implements security groups to control access to Nomad servers, clients, and other resources.
- **VPC Endpoints**: Creates VPC interface and gateway endpoints for services like S3, SSM, and CloudWatch Logs to improve security and performance.
- **WAF Integration**: Optionally enables AWS WAF for API Gateway to protect against common web exploits.

## Architecture Overview

![Architecture Diagram](/resources/image.png)

The infrastructure includes the following components:

1. **VPC**:
   - Public and private subnets across multiple availability zones.
   - Internet Gateway, NAT Gateway, and route tables for network routing.

2. **Nomad Cluster**:
   - Auto-scaling groups for Nomad servers and clients.
   - Bottlerocket AMIs for secure and lightweight instances.
   - Internal Network Load Balancer for server discovery.

3. **OIDC Provider**:
   - Configures an AWS IAM OpenID Connect provider for federated authentication.
   - Enables Nomad workloads to assume IAM roles using STS.

4. **Load Balancer**:
   - Application Load Balancer for Nomad UI with HTTPS support.
   - ACM certificate for secure communication.

5. **API Gateway**:
   - Exposes OIDC endpoints for Nomad workloads.
   - Integrated with VPC Link for secure communication.

6. **DNS**:
   - Public hosted zone for external access (e.g., `nomad.nomadsilo.com`).
   - Private hosted zone for internal service discovery.

7. **Security**:
   - Security groups for ALB, Nomad servers, clients, and VPC endpoints.
   - Fine-grained ingress and egress rules for secure communication.

8. **VPC Endpoints**:
   - Interface endpoints for services like SSM, EC2 Messages, and CloudWatch Logs.
   - Gateway endpoint for S3.

## Prerequisites

- AWS account with appropriate permissions.
- Terraform CLI installed.
- An existing EC2 key pair for SSH access to Nomad instances.
- A registered domain name and Route 53 hosted zone.

## Usage

1. Clone this repository:
   ```bash
   git clone https://github.com/your-repo/nomad-on-aws-infra.git
   cd nomad-on-aws-infra/terraform/envs/dev