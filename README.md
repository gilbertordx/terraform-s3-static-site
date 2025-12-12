# Terraform S3 Static Site

Production-ready Terraform module for deploying an S3 static website, with a Docker-based development environment.

## Features

- **Infrastructure as Code**: Modular Terraform config (DRY/SOLID principles)
- **Security**: SSE-S3 encryption, least-privilege bucket policy, Zero Trust aligned
- **Local Development**: Docker + LocalStack for free AWS emulation
- **Standards Enforced**: See `.github/` for CI/CD, security, testing, and code style guidelines

## Project Structure

```
.
├── .github/
│   ├── copilot-instructions.md   # AI/Copilot rules
│   ├── README.md                 # Priority matrix
│   └── standards/                # CI/CD, security, testing, git, code style
├── infra/
│   ├── index.html                # Static site content
│   ├── main.tf                   # Terraform resources
│   ├── outputs.tf                # Exported values
│   ├── providers.tf              # AWS provider config
│   ├── variables.tf              # Input variables
│   └── terraform.tfvars.example  # Example variable values
├── .gitignore
├── docker-compose.yml            # LocalStack + dev container
├── Dockerfile                    # Dev environment image
└── README.md
```

## Quick Start

### Prerequisites

- Docker Desktop installed and running

### 1. Clone and Start

```bash
git clone https://github.com/gilbertordx/terraform-s3-static-site.git
cd terraform-s3-static-site
docker compose up -d --build
```

### 2. Enter Dev Container

```bash
docker exec -it tf-dev bash
```

### 3. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 4. Deploy to LocalStack

```bash
terraform init
terraform plan
terraform apply
# Type 'yes' when prompted
```

### 5. Verify

```bash
curl http://localstack:4566/your-bucket-name/index.html
```

## Deploy to Real AWS

1. Set `use_localstack = false` in `terraform.tfvars`
2. Configure AWS credentials (`aws configure` or env vars)
3. Run `terraform apply`

## Standards

See `.github/README.md` for the priority matrix and enforcement details:

- **P0 (Blockers)**: No secrets in git, 80% test coverage, terraform validate, tfsec scan
- **P1 (Quality Gates)**: Code formatting, conventional commits, PR approval
- **P2 (Best Practices)**: Documentation, branch naming, logging

## License

MIT
