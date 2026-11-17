# ☁️ AWS Cloud Infrastructure (Terraform IaC)

Automated, production-grade Infrastructure as Code (IaC) provisioning the complete cloud topology for the **Estate Rental** ecosystem on **Amazon Web Services (AWS - `eu-west-1`)** using **Terraform** and official **AWS Registry Modules**.

---

## 🏛 AWS Infrastructure Architecture

![AWS EKS ```mermaid VPC Infrastructure Architecture](assets/aws_vpc_architecture.png)

<details><summary>Click to view Mermaid Diagram</summary>

```mermaid
graph TB
    subgraph VPC["VPC (10.0.0.0/16) - eu-west-1"]
        subgraph PublicAZ1["Public Subnet 1a (10.0.1.0/24)"]
            NAT["Single NAT Gateway"]
            ALB1["AWS Application Load Balancer"]
        end
        subgraph PublicAZ2["Public Subnet 1b (10.0.2.0/24)"]
            ALB2["AWS Application Load Balancer (Standby)"]
        end

        subgraph PrivateAZ1["Private Subnet 1a (10.0.10.0/24)"]
            EKSNode1["EKS Managed Node (t3.medium)"]
            RDSSub1["RDS Subnet AZ-a"]
        end
        subgraph PrivateAZ2["Private Subnet 1b (10.0.20.0/24)"]
            EKSNode2["EKS Managed Node (t3.medium)"]
            RDSSub2["RDS Subnet AZ-b"]
            RDSInstance[("RDS MySQL 8.0 db.t3.micro<br/>(gitops-estate-mysql)")]
        end
    end

    IGW["Internet Gateway"] --- PublicAZ1
    IGW --- PublicAZ2
    EKSNode1 -.->|Outbound internet via| NAT
    EKSNode2 -.->|Outbound internet via| NAT
    NAT --> IGW
    EKSNode1 -->|TCP 3306| RDSInstance
    EKSNode2 -->|TCP 3306| RDSInstance
    
    ECR["Amazon ECR (7 Repositories)"] -.->|Image Pull| EKSNode1
    SM["AWS Secrets Manager (DB Master Pass)"] -.->|IRSA CSI Secrets Driver| EKSNode1
    IAM_ALB["IAM Role (IRSA ALB Controller)"] -.->|ALB Ingress Management| ALB1

</details>
```

---

## 📂 File-by-File Breakdown

| File | Purpose & Architectural Role |
| :--- | :--- |
| [providers.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/providers.tf) | Configures the AWS provider targeting Ireland (`eu-west-1`) with default project tags (`Project = "GitOpsEstateRental"`, `ManagedBy = "Terraform"`). Declares the HashiCorp TLS provider for OIDC thumbprint verification. |
| [backend.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/backend.tf) | Sets up remote state storage in S3 bucket `gitops-estate-terraform-state` (`vpc/terraform.tfstate`) with AES-256 server-side encryption and modern native S3 state locking (`use_lockfile = true`). |
| [variables.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/variables.tf) | Declares input parameters including the Kubernetes version (`k8s_version = "1.34"`). |
| [vpc.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/vpc.tf) | Provisions the VPC using the official `terraform-aws-modules/vpc/aws` module (`v5.21.0`). Spans 2 Availability Zones (`eu-west-1a`, `eu-west-1b`) with 2 public subnets (`10.0.1.0/24`, `10.0.2.0/24`), 2 private subnets (`10.0.10.0/24`, `10.0.20.0/24`), and a single cost-optimized NAT Gateway. Applies discovery tags for the AWS Load Balancer Controller. |
| [routes.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/routes.tf) | Documents route table relationships (public route table directing `0.0.0.0/0` to IGW, private route table directing to NAT Gateway) managed declaratively by the VPC module. |
| [eks.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/eks.tf) | Deploys the production EKS cluster using `terraform-aws-modules/eks/aws`. Manages the Kubernetes control plane, managed node groups in private subnets, cluster security groups, KMS envelope encryption, and IAM access entries. |
| [addons.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/addons.tf) | Provisions managed EKS add-ons: AWS VPC CNI, CoreDNS, Kube-Proxy, and AWS EBS CSI Driver. |
| [oidc.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/oidc.tf) | Enables IAM OpenID Connect (OIDC) identity federation on the EKS cluster, the foundation for IAM Roles for Service Accounts (IRSA). |
| [iam.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/iam.tf) | Configures base node IAM roles and policies required for worker node registration and container runtime execution. |
| [iam_policy.json](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/iam_policy.json) | Complete AWS IAM policy document granting permission to manage ALBs, target groups, listeners, certificates, and WAF rules. |
| [irsa_alb.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/irsa_alb.tf) | Provisions the IRSA role for the AWS Load Balancer Controller, binding pod serviceaccount `aws-load-balancer-controller` in `kube-system` to AWS IAM without hardcoding credentials. |
| [irsa_rds.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/irsa_rds.tf) | Provisions the IRSA role `gitops-estate-rds-secret-accessor-role` for the Secrets Store CSI driver, allowing pods in `gitops-app-ns` to read RDS MySQL credentials from AWS Secrets Manager directly. |
| [security_groups.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/security_groups.tf) | Defines strict security boundaries: ALB SG (public HTTP/HTTPS ports 80/443), EKS Worker Nodes SG (inbound from ALB SG), and RDS MySQL SG (inbound port 3306 restricted strictly to the EKS Worker Nodes SG). |
| [rds.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/rds.tf) | Provisions an AWS RDS MySQL 8.0 instance (`db.t3.micro`, 20GB–50GB autoscaling) in the private DB subnet group. Automatically creates a 16-character password via `random_password` and registers connection credentials in AWS Secrets Manager (`gitops-estate-mysql-credentials`). |
| [ecr.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/ecr.tf) | Provisions 7 Amazon ECR repositories (`gitops-estate/<service>`) with tag mutability, automatic push-time vulnerability scanning, AES-256 encryption, and lifecycle cleanup policies deleting untagged images older than 1 day. |
| [outputs.tf](file:///home/yahya-ahmane/gitops_estate_rental/terraform_infra/outputs.tf) | Outputs cluster name, API endpoint, VPC ID, private subnet IDs, RDS endpoint, and ECR repository URLs. |

---

## 🚀 Execution & Management

### Prerequisites
- AWS CLI configured with administrator privileges (`aws configure`)
- Terraform CLI >= 1.0.0

### Apply Infrastructure
```bash
# Initialize providers and remote backend
terraform init

# Validate syntax and module configuration
terraform validate

# Plan and review changes
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

### Connect to the Cluster
```bash
aws eks update-kubeconfig --region eu-west-1 --name gitops-estate-cluster
```

