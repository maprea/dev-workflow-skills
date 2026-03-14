# IaC Patterns

## Contents
- Terraform module pattern
- State management patterns
- Security patterns
- Common anti-patterns

## Terraform Module Pattern

### Module structure
```
modules/database/
├── main.tf          # Resource definitions
├── variables.tf     # Input variables with descriptions and validation
├── outputs.tf       # Output values for consumers
├── versions.tf      # Required provider versions
└── README.md        # Usage documentation
```

### Well-defined variables
```hcl
variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
  validation {
    condition     = can(regex("^db\\.", var.instance_class))
    error_message = "Instance class must start with 'db.'"
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}
```

### Consistent tagging
```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Team        = var.team
  }
}

resource "aws_db_instance" "main" {
  # ... configuration ...
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })
}
```

## State Management Patterns

### Remote backend (Terraform + AWS)
```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "environments/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Rules:
- One state file per environment per component. Never share state across environments.
- Enable encryption on the state bucket (state contains secrets).
- Enable DynamoDB locking to prevent concurrent applies.
- Enable versioning on the state bucket for recovery.
- Never commit `.tfstate` files to git.

### Environment separation
```
environments/
├── dev/
│   ├── main.tf           # module "db" { source = "../../modules/database" ... }
│   └── terraform.tfvars  # instance_class = "db.t3.micro"
├── staging/
│   ├── main.tf
│   └── terraform.tfvars  # instance_class = "db.t3.small"
└── production/
    ├── main.tf
    └── terraform.tfvars  # instance_class = "db.r6g.large"
```

Each environment has its own state, its own tfvars, and composes the same modules with different parameters.

## Security Patterns

### Least-privilege security groups
```hcl
# GOOD: Specific port, specific source
resource "aws_security_group_rule" "api_from_alb" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.api.id
}

# BAD: Open to the world
resource "aws_security_group_rule" "bad_example" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]  # Never do this
  security_group_id = aws_security_group.api.id
}
```

### Encryption by default
```hcl
resource "aws_db_instance" "main" {
  storage_encrypted = true  # Always
  # ...
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
```

### No hardcoded secrets
```hcl
# BAD
resource "aws_db_instance" "main" {
  password = "supersecret123"
}

# GOOD: Use a secrets manager or variable with sensitive flag
variable "db_password" {
  type      = string
  sensitive = true
}

# BETTER: Generate and store in secrets manager
resource "random_password" "db" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}
```

## Common Anti-patterns

**Mega-module**: One giant module that creates VPC + RDS + ECS + CloudFront. Split into focused, composable modules.

**Hardcoded values**: Region, account ID, instance sizes baked into resource blocks. Use variables with validation.

**No state locking**: Two engineers running `terraform apply` simultaneously can corrupt state. Always enable locking.

**Local state**: State on someone's laptop means no collaboration and no recovery. Always use remote backends.

**Apply from laptop**: Manual applies bypass code review and audit trails. Apply through CI/CD only. `terraform plan` locally for development, `terraform apply` through pipelines.

**Ignoring plan output**: Applying without reading the plan. Always review what will be created, changed, or destroyed — especially in production.
