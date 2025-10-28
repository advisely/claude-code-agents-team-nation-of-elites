---
name: terraform-patterns
description: Terraform Infrastructure as Code patterns, modules, state management, and cloud resource provisioning best practices
---

# Terraform Infrastructure Patterns

## When to Use This Skill

- Provisioning cloud infrastructure
- Managing infrastructure as code
- Creating reusable Terraform modules
- Multi-environment deployments
- Following Terraform best practices

## Target Agents

- `devops-engineer` - Primary user
- `cloud-architect` - Infrastructure design
- `infrastructure-specialist` - Resource management

## Core Patterns

### 1. Module Structure

```hcl
# modules/ec2-instance/main.tf
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )
}

# modules/ec2-instance/variables.tf
variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# modules/ec2-instance/outputs.tf
output "instance_id" {
  description = "ID of created instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of instance"
  value       = aws_instance.this.public_ip
}
```

### 2. Remote State

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# State locking with DynamoDB
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### 3. Multi-Environment Setup

```hcl
# environments/prod/main.tf
module "vpc" {
  source = "../../modules/vpc"

  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  tags = {
    Environment = "prod"
    Managed_by  = "terraform"
  }
}

module "app" {
  source = "../../modules/application"

  environment         = "prod"
  instance_type       = "t3.large"
  desired_capacity    = 5
  max_size            = 10
}
```

## Best Practices

1. Use **modules** for reusability
2. Implement **remote state**
3. Use **workspaces** for environments
4. Version **provider** versions
5. Use **variables** and **locals**
6. Implement **state locking**
7. Use **data sources** for existing resources
8. Tag **all resources**
9. Use **terraform fmt** and **validate**
10. Store secrets in **vault/ssm**
